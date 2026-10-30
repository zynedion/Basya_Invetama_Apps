import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:basya_investama/features/auth/domain/auth_session.dart';
import 'package:basya_investama/features/auth/data/auth_exception.dart';
import 'package:basya_investama/features/savings/data/savings_api_client.dart';
import 'package:basya_investama/features/savings/domain/savings_gateway.dart';

void main() {
  final session = AuthSession(
    accessToken: 'test',
    tokenType: 'Bearer',
    expiresAt: DateTime(2030),
  );
  final fixture = File(
    'test/features/savings/savings_response.json',
  ).readAsStringSync();
  test(
    'maps provided response and sends authorized optional filters',
    () async {
      final requests = <http.Request>[];
      final api = SavingsApiClient(
        client: MockClient((request) async {
          requests.add(request);
          return http.Response(fixture, 200);
        }),
      );
      addTearDown(api.close);
      final data = await api.getSavings(session, limit: 5);
      expect(data.total, 950899);
      expect(data.voluntarySavings, 899);
      expect(data.principalSavings, 350000);
      expect(data.mandatorySavings, 600000);
      expect(data.annualShu, isNull);
      expect(data.transactions.length, 14);
      expect(data.transactions.first.referenceId, 'I261012154114214');
      expect(data.transactions.first.status, 'Berhasil');
      expect(requests.first.headers['Authorization'], 'Bearer test');
      expect(requests.first.url.queryParameters, {'limit': '5'});
      for (final type in SavingsType.values) {
        await api.getSavings(session, type: type);
        expect(requests.last.url.queryParameters, {'type': type.name});
      }
      await api.getSavings(session);
      expect(requests.last.url, SavingsApiClient.savingsUri);
      await api.getSavings(session, type: SavingsType.wajib, limit: 5);
      expect(requests.last.url.queryParameters, {
        'type': 'wajib',
        'limit': '5',
      });
    },
  );
  test(
    'empty history is valid; malformed balances fail instead of becoming zero',
    () async {
      final body = jsonDecode(fixture) as Map<String, dynamic>;
      body['data']['histories'] = [];
      final api = SavingsApiClient(
        client: MockClient((_) async => http.Response(jsonEncode(body), 200)),
      );
      addTearDown(api.close);
      expect((await api.getSavings(session)).transactions, isEmpty);
      body['data']['balances'].remove('pokok');
      await expectLater(
        api.getSavings(session),
        throwsA(
          isA<AuthException>().having(
            (e) => e.type,
            'type',
            AuthFailureType.invalidResponse,
          ),
        ),
      );
    },
  );
  test(
    'unauthorized response reports expired session even for non JSON',
    () async {
      final api = SavingsApiClient(
        client: MockClient((_) async => http.Response('Unauthorized', 401)),
      );
      addTearDown(api.close);
      await expectLater(
        api.getSavings(session),
        throwsA(
          isA<AuthException>().having(
            (e) => e.type,
            'type',
            AuthFailureType.invalidCredentials,
          ),
        ),
      );
    },
  );
}
