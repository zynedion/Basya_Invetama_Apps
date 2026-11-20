import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:basya_investama/features/auth/domain/auth_session.dart';
import 'package:basya_investama/features/savings/data/savings_topup_api.dart';

void main() {
  final session = AuthSession(
    accessToken: 'test',
    tokenType: 'Bearer',
    expiresAt: DateTime.utc(2030),
  );
  for (final buyPower in [false, true]) {
    final createApi = buyPower ? SavingsTopUpApi.buyPower : SavingsTopUpApi.new;
    final path = buyPower ? '/app/investasi/topup' : '/app/simpanan/topup';
    test(
      '$path options reads real destination IDs and account numbers',
      () async {
        final api = createApi(
          client: MockClient((request) async {
            expect(request.url.path, '$path/options');
            expect(request.headers['Authorization'], 'Bearer test');
            return http.Response(
              jsonEncode({
                'status': true,
                'data': {
                  'bank_accounts': [
                    {
                      'id': 7,
                      'bank_name': 'Bank',
                      'account_name': 'Basya',
                      'account_no': '001234',
                    },
                  ],
                },
              }),
              200,
            );
          }),
        );
        final accounts = await api.options(session);
        expect(accounts.single['id'], 7);
        expect(accounts.single['account_no'], '001234');
        api.dispose();
      },
    );
    test(
      '$path multipart sends selected ID, date, amount and PDF bytes once',
      () async {
        var calls = 0;
        final api = createApi(
          client: MockClient((request) async {
            calls++;
            expect(request.method, 'POST');
            expect(request.url.path, path);
            expect(request.headers['Authorization'], 'Bearer test');
            expect(
              request.headers['content-type'],
              contains('multipart/form-data'),
            );
            final body = latin1.decode(request.bodyBytes);
            expect(body, contains('name="acc_bank_id"\r\n\r\n7'));
            expect(body, contains('name="amount"\r\n\r\n100000'));
            expect(body, contains('2026-11-13'));
            expect(
              body,
              contains('name="payment_proof"; filename="proof.pdf"'),
            );
            expect(body, contains('application/pdf'));
            expect(body, contains('%PDF-test'));
            expect(body, isNot(contains('nasabah_id')));
            expect(body, isNot(contains('investor_id')));
            expect(
              body,
              contains('name="note"\r\n\r\n${'x' * (buyPower ? 100 : 50)}'),
            );
            return http.Response(
              '{"status":true,"data":{"topup":{"trx_id":"TEST","status":{"code":"unverified"}}}}',
              201,
            );
          }),
        );
        final result = await api.submit(
          session,
          date: DateTime(2026, 11, 13),
          amount: 100000,
          accountId: 7,
          filename: 'proof.pdf',
          bytes: Uint8List.fromList(utf8.encode('%PDF-test')),
          note: 'x' * (buyPower ? 100 : 50),
        );
        expect(result['status']['code'], 'unverified');
        expect(calls, 1);
        api.dispose();
      },
    );
    test('$path 401 mutation is not replayed', () async {
      var calls = 0;
      final api = createApi(
        client: MockClient((_) async {
          calls++;
          return http.Response(
            '{"status":false,"message":"Invalid token"}',
            401,
          );
        }),
      );
      await expectLater(
        api.submit(
          session,
          date: DateTime(2026, 11, 13),
          amount: 1,
          accountId: 7,
          filename: 'proof.png',
          bytes: Uint8List.fromList([1]),
          note: '',
        ),
        throwsA(isA<SavingsTopUpFailure>()),
      );
      expect(calls, 1);
      api.dispose();
    });
  }
}
