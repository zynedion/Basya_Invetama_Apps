import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:basya_investama/features/auth/domain/auth_session.dart';
import 'package:basya_investama/features/forms/presentation/form_widgets.dart';
import 'package:basya_investama/features/multiguna/data/multiguna_payment_api.dart';
import 'package:basya_investama/features/multiguna/presentation/multiguna_payment_page.dart';

void main() {
  final session = AuthSession(
    accessToken: 'test',
    tokenType: 'Bearer',
    expiresAt: DateTime.utc(2030),
  );
  test(
    'exact settlement accepts rounding, rejects arbitrary and excessive amounts',
    () {
      final rule = {
        'minimum': 295294,
        'multiple_of': 295294,
        'maximum': 4429412,
        'settlement_amount': 4429412,
      };
      expect(validateInstallmentAmount(590588, rule), isNull);
      expect(validateInstallmentAmount(4429412, rule), isNull);
      for (final amount in [0, 200000, 590589, 4429413]) {
        expect(validateInstallmentAmount(amount, rule), isNotNull);
      }
    },
  );
  test(
    'selected contract ID, preview body, pending envelope and multipart payment',
    () async {
      final calls = <http.Request>[];
      final api = MultigunaPaymentApi(
        client: MockClient((r) async {
          calls.add(r);
          expect(r.headers['Authorization'], 'Bearer test');
          final Map data;
          if (r.url.path.endsWith('/pending')) {
            data = {
              'payments': [
                {'landing_id': 292},
              ],
            };
          } else if (r.url.path.endsWith('/options')) {
            data = {
              'contract': {'id': 292},
            };
          } else if (r.url.path.endsWith('/preview')) {
            expect(jsonDecode(r.body), {'amount': 590588});
            data = {
              'payment': {'amount': 590588},
            };
          } else {
            expect(r.url.path, '/app/multiguna/292/payment');
            final body = latin1.decode(r.bodyBytes);
            expect(body, contains('name="amount"\r\n\r\n590588'));
            expect(body, contains('name="acc_bank_id"\r\n\r\n2'));
            expect(body, contains('2026-11-23'));
            expect(body, contains('filename="proof.pdf"'));
            expect(body, isNot(contains('installment_to')));
            data = {
              'payment': {
                'id': 125,
                'status': {'code': 'pending'},
              },
            };
          }
          return http.Response(jsonEncode({'status': true, 'data': data}), 200);
        }),
      );
      await api.options(session, 292);
      await api.preview(session, 292, 590588);
      expect((await api.pending(session)).single['landing_id'], 292);
      final result = await api.submit(
        session,
        292,
        amount: 590588,
        date: DateTime(2026, 11, 23),
        accountId: 2,
        note: 'Dua cicilan',
        proof: LocalAttachment(
          name: 'proof.pdf',
          bytes: Uint8List.fromList([37, 80, 68, 70]),
          isImage: false,
        ),
      );
      expect(result['id'], 125);
      expect(calls.length, 4);
      expect(calls[0].url.path, '/app/multiguna/292/payment/options');
      expect(calls[1].url.path, '/app/multiguna/292/payment/preview');
      api.dispose();
    },
  );
  for (final status in [401, 500]) {
    test('submission $status never retries', () async {
      var calls = 0;
      final api = MultigunaPaymentApi(
        client: MockClient((r) async {
          calls++;
          return http.Response('{"status":false,"message":"error"}', status);
        }),
      );
      await expectLater(
        api.submit(
          session,
          292,
          amount: 295294,
          date: DateTime(2026, 11, 23),
          accountId: 1,
          note: '',
          proof: LocalAttachment(
            name: 'p.png',
            bytes: Uint8List.fromList([1]),
            isImage: true,
          ),
        ),
        throwsA(isA<MultigunaPaymentFailure>()),
      );
      expect(calls, 1);
      api.dispose();
    });
  }
}
