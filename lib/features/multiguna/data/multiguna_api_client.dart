import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../auth/data/auth_exception.dart';
import '../../auth/domain/auth_session.dart';
import '../domain/multiguna_gateway.dart';
import '../domain/multiguna_overview_data.dart';

class MultigunaApiClient implements MultigunaGateway {
  MultigunaApiClient({http.Client? client}) : _client = client ?? http.Client();

  static final Uri multigunaUri = Uri.parse(
    'https://api.basyainvestama.id/app/multiguna',
  );

  final http.Client _client;

  @override
  Future<MultigunaOverviewData> getOverview(AuthSession session) async {
    try {
      final response = await _client
          .get(
            multigunaUri,
            headers: {
              'Accept': 'application/json',
              'Authorization': session.authorizationHeader,
            },
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 403) return MultigunaOverviewData.unavailable;
      final body = _decodeBody(response.body);
      if (response.statusCode == 200) return _parseOverview(body);
      if (response.statusCode == 401) {
        throw const AuthException(
          AuthFailureType.invalidCredentials,
          'Sesi Anda sudah tidak berlaku. Silakan masuk kembali.',
        );
      }
      if (response.statusCode >= 500) {
        throw const AuthException(
          AuthFailureType.server,
          'Data Multiguna belum dapat dimuat. Silakan coba lagi nanti.',
        );
      }
      throw AuthException(
        AuthFailureType.server,
        _extractMessage(body) ?? 'Data Multiguna belum dapat dimuat.',
      );
    } on AuthException {
      rethrow;
    } on TimeoutException {
      throw const AuthException(
        AuthFailureType.timeout,
        'Waktu memuat Multiguna habis. Silakan coba lagi.',
      );
    } on http.ClientException {
      throw const AuthException(
        AuthFailureType.connection,
        'Tidak dapat memuat Multiguna. Periksa koneksi internet Anda.',
      );
    } on FormatException {
      throw const AuthException(
        AuthFailureType.invalidResponse,
        'Respons Multiguna server tidak dapat dibaca.',
      );
    }
  }

  Map<String, dynamic> _decodeBody(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) throw const FormatException();
    return decoded;
  }

  MultigunaOverviewData _parseOverview(Map<String, dynamic> body) {
    final data = body['data'];
    if (body['status'] != true || data is! Map) throw const FormatException();
    final rawLoans = data['multiguna'];
    if (rawLoans is! List) throw const FormatException();

    int number(Map source, String key) {
      final value = source[key];
      if (value is! num) throw const FormatException();
      return value.toInt();
    }

    String text(Map source, String key) {
      final value = source[key];
      if (value is! String) throw const FormatException();
      return value;
    }

    DateTime date(Map source, String key) {
      final value = DateTime.tryParse(text(source, key));
      if (value == null) throw const FormatException();
      return value;
    }

    final loans = <MultigunaLoan>[];
    for (final raw in rawLoans) {
      if (raw is! Map) throw const FormatException();
      final progress = raw['installment_progress'];
      final collectibility = raw['collectibility'];
      final paymentStatus = raw['payment_status'];
      final arrears = raw['arrears'];
      if (progress is! Map ||
          collectibility is! Map ||
          paymentStatus is! Map ||
          arrears is! Map) {
        throw const FormatException();
      }
      loans.add(
        MultigunaLoan(
          contractNumber: text(raw, 'trx_id'),
          startDate: date(raw, 'start_date'),
          endDate: date(raw, 'end_date'),
          installmentAmount: number(raw, 'installment'),
          totalPayment: number(raw, 'total_payment'),
          remainingBalance: number(raw, 'outstanding'),
          dueDay: number(raw, 'due_day'),
          nextDueDate: date(raw, 'next_due_date'),
          paidInstallments: number(progress, 'paid'),
          totalInstallments: number(progress, 'total'),
          nextInstallmentNumber: number(progress, 'next'),
          collectibilityValue: number(collectibility, 'value'),
          collectibilityLabel: text(collectibility, 'label'),
          collectibilityCategory: text(collectibility, 'category'),
          paymentStatusCode: text(paymentStatus, 'code'),
          paymentStatusLabel: text(paymentStatus, 'label'),
          arrearsMonths: number(arrears, 'months'),
          arrearsAmount: number(arrears, 'amount'),
        ),
      );
    }
    final currency = data['currency'];
    final hasMultiguna = data['has_multiguna'];
    if (currency is! String || hasMultiguna is! bool) {
      throw const FormatException();
    }
    return MultigunaOverviewData(
      accessible: true,
      currency: currency,
      hasMultiguna: hasMultiguna,
      totalContracts: number(data, 'total_contracts'),
      totalInstallment: number(data, 'total_installment'),
      totalObligation: number(data, 'total_outstanding'),
      loans: List.unmodifiable(loans),
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
