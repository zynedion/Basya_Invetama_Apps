import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:basya_investama/features/auth/domain/auth_session.dart';
import 'package:basya_investama/features/investment/data/investment_mutation_api.dart';
import 'package:basya_investama/features/investment/presentation/investment_mutation_page.dart';

void main() {
  final session = AuthSession(
    accessToken: 'test',
    tokenType: 'Bearer',
    expiresAt: DateTime.utc(2030),
  );
  testWidgets(
    'expired OTP can resend on same application then verify leading zero code',
    (tester) async {
      final calls = <http.Request>[];
      final api = InvestmentMutationApi(
        client: MockClient((r) async {
          calls.add(r);
          return http.Response(
            jsonEncode({
              'status': true,
              'data': r.url.path.endsWith('resend-otp')
                  ? {
                      'mutation_id': 1218,
                      'otp': {
                        'sent': true,
                        'expires_in': 1800,
                        'remaining_attempts': 5,
                        'can_resend': false,
                        'resend_in_seconds': 60,
                        'resend_count': 1,
                        'resend_limit': 3,
                      },
                    }
                  : {
                      'mutation': {
                        'id': 1218,
                        'status': {'code': 'completed'},
                      },
                      'otp': {'verified': true},
                    },
            }),
            200,
          );
        }),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: InvestmentMutationOtpPage(
            session: session,
            api: api,
            item: {
              'id': 1218,
              'amount': 1000000,
              'status': {'code': 'waiting_otp'},
              'otp': {
                'expired': true,
                'remaining_seconds': 0,
                'remaining_attempts': 0,
                'can_resend': true,
                'resend_in_seconds': 0,
                'resend_count': 0,
                'resend_limit': 3,
              },
            },
          ),
        ),
      );
      final resend = find.text('Kirim ulang kode');
      await tester.scrollUntilVisible(
        resend,
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(resend);
      await tester.pumpAndSettle();
      expect(calls.single.url.path, endsWith('/1218/resend-otp'));
      expect(find.text('Kirim ulang dalam 60 detik'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '001234');
      final verify = find.text('Verifikasi & pindahkan saldo');
      await tester.ensureVisible(verify);
      await tester.pumpAndSettle();
      await tester.tap(verify);
      await tester.pumpAndSettle();
      expect(jsonDecode(calls.last.body)['otp'], '001234');
      expect(find.text('Mutasi berhasil'), findsOneWidget);
      expect(find.text('Menunggu verifikasi admin'), findsNothing);
      expect(calls.length, 2);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );
}
