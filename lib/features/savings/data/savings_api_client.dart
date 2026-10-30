import '../../auth/data/authorized_request.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../auth/data/auth_exception.dart';
import '../../auth/domain/auth_session.dart';
import '../domain/savings_gateway.dart';
import '../domain/savings_overview_data.dart';

class SavingsApiClient implements SavingsGateway {
  SavingsApiClient({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  static final savingsUri = Uri.parse(
    'https://api.basyainvestama.id/app/simpanan',
  );
  void close() => _client.close();

  @override
  Future<SavingsOverviewData> getSavings(
    AuthSession session, {
    SavingsType? type,
    int? limit,
  }) async {
    final query = {
      if (type != null) 'type': type.name,
      if (limit != null) 'limit': '$limit',
    };
    try {
      final response = await authorizedGet(
        _client,
        query.isEmpty ? savingsUri : savingsUri.replace(queryParameters: query),
        session,
        headers: {
          'Accept': 'application/json',
          'Authorization': session.authorizationHeader,
        },
      );
      if (response.statusCode == 401) {
        throw const AuthException(
          AuthFailureType.invalidCredentials,
          'Sesi Anda sudah tidak berlaku. Silakan masuk kembali.',
        );
      }
      if (response.statusCode != 200) {
        throw const AuthException(
          AuthFailureType.server,
          'Simpanan belum dapat dimuat. Silakan coba lagi.',
        );
      }
      final body = jsonDecode(response.body);
      if (body is! Map || body['status'] != true || body['data'] is! Map) {
        throw const FormatException();
      }
      final data = body['data'] as Map;
      if (data['currency'] != 'IDR' ||
          data['balances'] is! Map ||
          data['histories'] is! List) {
        throw const FormatException();
      }
      final balances = data['balances'] as Map;
      return SavingsOverviewData(
        total: _number(balances['total']),
        voluntarySavings: _number(balances['sukarela']),
        mandatorySavings: _number(balances['wajib']),
        principalSavings: _number(balances['pokok']),
        transactions: (data['histories'] as List).map(_transaction).toList(),
      );
    } on TimeoutException {
      throw const AuthException(
        AuthFailureType.timeout,
        'Waktu memuat simpanan habis. Silakan coba lagi.',
      );
    } on http.ClientException {
      throw const AuthException(
        AuthFailureType.connection,
        'Periksa koneksi internet Anda lalu coba lagi.',
      );
    } on FormatException {
      throw const AuthException(
        AuthFailureType.invalidResponse,
        'Respons simpanan server tidak dapat dibaca.',
      );
    }
  }

  static int _number(dynamic value) {
    if (value is! num || !value.isFinite || value != value.roundToDouble()) {
      throw const FormatException();
    }
    return value.toInt();
  }

  static String _string(dynamic value) {
    if (value is! String) throw const FormatException();
    return value;
  }

  static SavingsTransaction _transaction(dynamic item) {
    if (item is! Map || item['status'] is! Map) throw const FormatException();
    final date = DateTime.tryParse(_string(item['occurred_at']));
    if (date == null) throw const FormatException();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final amount = _number(item['amount']);
    if (amount < 0) throw const FormatException();
    return SavingsTransaction(
      id: _string(item['id']),
      title: _string(item['title']),
      savingsType: _string(item['savings_type']),
      referenceId: _string(item['reference_id']),
      date:
          '${date.day} ${months[date.month - 1]} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
      status: _string(item['status']['label']),
      statusCode: _string(item['status']['code']),
      amount: amount,
      direction: switch (item['direction']) {
        'incoming' => SavingsTransactionDirection.incoming,
        'outgoing' => SavingsTransactionDirection.outgoing,
        'transfer' => SavingsTransactionDirection.neutral,
        _ => throw const FormatException(),
      },
    );
  }
}
