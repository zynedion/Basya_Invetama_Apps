import 'dart:convert';

import 'package:basya_investama/features/auth/domain/auth_session.dart';
import 'package:basya_investama/features/multiguna/data/multiguna_api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final session = AuthSession(
    accessToken: 'test-token',
    tokenType: 'Bearer',
    expiresAt: DateTime.utc(2026, 9, 22),
  );

  test('maps active Multiguna contracts and sends bearer token', () async {
    late http.Request captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(
        jsonEncode({
          'status': true,
          'message': 'Data multiguna berhasil diambil',
          'data': {
            'currency': 'IDR',
            'has_multiguna': true,
            'total_contracts': 1,
            'total_installment': 750000,
            'total_outstanding': 10000000,
            'multiguna': [
              {
                'trx_id': 'L260101000001',
                'start_date': '2026-01-01',
                'end_date': '2027-01-17',
                'installment': 750000,
                'total_payment': 4500000,
                'outstanding': 10000000,
                'due_day': 17,
                'next_due_date': '2026-07-17',
                'installment_progress': {'paid': 6, 'total': 24, 'next': 7},
                'collectibility': {
                  'value': -1,
                  'label': 'COL -1',
                  'category': 'warning',
                },
                'payment_status': {
                  'code': 'overdue',
                  'label': 'Cicilan Belum Dibayar',
                },
                'arrears': {'months': 1, 'amount': 750000},
              },
            ],
          },
        }),
        200,
      );
    });

    final result = await MultigunaApiClient(
      client: client,
    ).getOverview(session);

    expect(captured.method, 'GET');
    expect(captured.url, MultigunaApiClient.multigunaUri);
    expect(captured.headers['Authorization'], 'Bearer test-token');
    expect(result.hasActiveLoan, isTrue);
    expect(result.totalObligation, 10000000);
    expect(result.nearestLoan?.arrearsAmount, 750000);
    expect(result.nearestLoan?.paidProgress, .25);
  });

  test('maps empty Multiguna response without creating dummy loans', () async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'status': true,
          'data': {
            'currency': 'IDR',
            'has_multiguna': false,
            'total_contracts': 0,
            'total_installment': 0,
            'total_outstanding': 0,
            'multiguna': [],
          },
        }),
        200,
      ),
    );

    final result = await MultigunaApiClient(
      client: client,
    ).getOverview(session);

    expect(result.accessible, isTrue);
    expect(result.hasActiveLoan, isFalse);
    expect(result.loans, isEmpty);
  });

  test('maps forbidden response to unavailable instead of an error', () async {
    final client = MockClient((_) async => http.Response('{}', 403));

    final result = await MultigunaApiClient(
      client: client,
    ).getOverview(session);

    expect(result.accessible, isFalse);
    expect(result.hasActiveLoan, isFalse);
  });
}
