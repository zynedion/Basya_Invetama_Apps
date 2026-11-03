import '../../auth/data/authorized_request.dart';
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../auth/data/auth_exception.dart';
import '../../auth/domain/auth_session.dart';
import '../domain/home_summary.dart';
import '../domain/home_summary_gateway.dart';

class HomeSummaryApiClient implements HomeSummaryGateway {
  HomeSummaryApiClient({http.Client? client})
    : _client = client ?? http.Client();

  static final Uri summaryUri = Uri.parse(
    'https://api.basyainvestama.id/app/summary',
  );

  final http.Client _client;
  void close() => _client.close();

  @override
  Future<HomeSummary> getSummary(AuthSession session) async {
    try {
      final response = await authorizedGet(
        _client,
        summaryUri,
        session,
        headers: {
          'Accept': 'application/json',
          'Authorization': session.authorizationHeader,
        },
      );
      final body = _decodeBody(response.body);
      if (response.statusCode == 200) return _parseSummary(body);
      if (response.statusCode == 401) {
        throw const AuthException(
          AuthFailureType.invalidCredentials,
          'Sesi Anda sudah tidak berlaku. Silakan masuk kembali.',
        );
      }
      if (response.statusCode == 403) {
        throw const AuthException(
          AuthFailureType.server,
          'Akun ini tidak memiliki akses ke ringkasan.',
        );
      }
      if (response.statusCode >= 500) {
        throw const AuthException(
          AuthFailureType.server,
          'Ringkasan belum dapat dimuat. Silakan coba lagi nanti.',
        );
      }
      throw AuthException(
        AuthFailureType.server,
        _extractMessage(body) ?? 'Ringkasan belum dapat dimuat.',
      );
    } on AuthException {
      rethrow;
    } on TimeoutException {
      throw const AuthException(
        AuthFailureType.timeout,
        'Waktu memuat ringkasan habis. Silakan coba lagi.',
      );
    } on http.ClientException {
      throw const AuthException(
        AuthFailureType.connection,
        'Tidak dapat memuat ringkasan. Periksa koneksi internet Anda.',
      );
    } on FormatException {
      throw const AuthException(
        AuthFailureType.invalidResponse,
        'Respons ringkasan server tidak dapat dibaca.',
      );
    }
  }

  Map<String, dynamic> _decodeBody(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) throw const FormatException();
    return decoded;
  }

  HomeSummary _parseSummary(Map<String, dynamic> body) {
    final data = body['data'];
    if (body['status'] != true || data is! Map) {
      throw const FormatException();
    }
    final period = data['period'];
    final totals = data['totals'];
    if (period is! Map || totals is! Map) throw const FormatException();

    int number(Map source, String key) {
      final value = source[key];
      if (value is! num) throw const FormatException();
      return value.toInt();
    }

    final scopeValue = data['scope'];
    final currency = data['currency'];
    if (scopeValue is! String || currency is! String) {
      throw const FormatException();
    }
    final scope = switch (scopeValue.toLowerCase()) {
      'personal' => HomeSummaryScope.personal,
      'global' => HomeSummaryScope.global,
      _ => throw const FormatException(),
    };

    final performance = data['performa_investasi'];
    final points = <InvestmentPerformancePoint>[];
    int? performanceMonths;
    String? performanceType;
    if (performance != null) {
      if (performance is! Map ||
          performance['data'] is! List ||
          performance['tipe'] is! String) {
        throw const FormatException();
      }
      performanceMonths = number(performance, 'periode_bulan');
      performanceType = performance['tipe'] as String;
      for (final point in performance['data'] as List) {
        if (point is! Map || point['label'] is! String) {
          throw const FormatException();
        }
        final month = number(point, 'month');
        if (month < 1 || month > 12) throw const FormatException();
        points.add(
          InvestmentPerformancePoint(
            year: number(point, 'year'),
            month: month,
            label: point['label'] as String,
            profit: number(point, 'profit'),
          ),
        );
      }
    }
    return HomeSummary(
      totalInvestmentValue: totals['total_nilai_investasi'] == null
          ? null
          : number(totals, 'total_nilai_investasi'),
      performanceMonths: performanceMonths,
      performanceType: performanceType,
      performance: List.unmodifiable(points),
      scope: scope,
      currency: currency,
      year: number(period, 'year'),
      month: number(period, 'month'),
      totalBalance: number(totals, 'total_saldo'),
      buyPower: number(totals, 'buy_power'),
      voluntarySavings: number(totals, 'simpanan_sukarela'),
      principalSavings: number(totals, 'simpanan_pokok'),
      mandatorySavings: number(totals, 'simpanan_wajib'),
      investedFunds: number(totals, 'dana_aktif_diinvestasikan'),
      monthlyProfit: number(totals, 'profit_bulan_berjalan'),
      accumulatedProfit: number(totals, 'akumulasi_total_profit'),
    );
  }

  String? _extractMessage(Map<String, dynamic> body) {
    final messages = body['messages'];
    if (messages is Map && messages['error'] is String) {
      return messages['error'] as String;
    }
    return body['message'] is String ? body['message'] as String : null;
  }
}
