import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:basya_investama/core/widgets/basya_components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:basya_investama/features/auth/domain/auth_session.dart';
import 'package:basya_investama/features/investment/data/investment_purchase_api.dart';
import 'package:basya_investama/features/investment/presentation/investment_sale_page.dart';
import 'package:basya_investama/features/investment/presentation/investment_purchase_otp_page.dart';

void main() {
  final session = AuthSession(
    accessToken: 'test',
    tokenType: 'Bearer',
    expiresAt: DateTime.utc(2099),
  );
  http.Response ok(Map data, [int status = 200]) =>
      http.Response(jsonEncode({'status': true, 'data': data}), status);
  test('lot validation uses server limits', () {
    final options = {
      'constraints': {'minimum_lot': 1, 'maximum_lot': 2},
    };
    expect(validateSaleLots('2', options), isNull);
    for (final value in ['0', '-1', '1.5', '3', '']) {
      expect(validateSaleLots(value, options), isNotNull);
    }
    expect(
      validateSaleLots('1', {
        'constraints': {'minimum_lot': 1, 'maximum_lot': 0},
      }),
      isNotNull,
    );
  });
  test(
    'selected stock, exact create body, order OTP routes and pending envelope',
    () async {
      final paths = <String>[];
      final api = InvestmentPurchaseApi.sale(
        client: MockClient((r) async {
          paths.add(r.url.path);
          expect(r.headers['Authorization'], 'Bearer test');
          if (r.url.path.endsWith('/options')) {
            return ok({
              'stock': {'id': 8},
            });
          }
          if (r.url.path.endsWith('/penjualan/8')) {
            expect(jsonDecode(r.body), {'total_lot': 2});
            return ok({
              'sale': {'id': 125, 'stock_id': 8},
            }, 201);
          }
          if (r.url.path.endsWith('/verify-otp')) {
            expect(jsonDecode(r.body), {'otp': '001234'});
            return ok({'next_action': 'admin_approval'});
          }
          if (r.url.path.endsWith('/resend-otp')) {
            expect(r.body, isEmpty);
            return http.Response('{"status":true,"message":"sent"}', 200);
          }
          expect(r.url.queryParameters, {'type': 'penjualan'});
          return ok({
            'pengajuan': [
              {'id': 125},
            ],
            'scope': 'personal',
          });
        }),
      );
      await api.options(session, 8);
      expect((await api.create(session, 8, 2))['sale']['id'], 125);
      await api.verify(session, 125, '001234');
      await api.resend(session, 125);
      expect((await api.pending(session)).single['id'], 125);
      expect(paths, [
        '/app/investasi/penjualan/8/options',
        '/app/investasi/penjualan/8',
        '/app/investasi/pengajuan/125/verify-otp',
        '/app/investasi/pengajuan/125/resend-otp',
        '/app/investasi/pengajuan',
      ]);
      api.dispose();
    },
  );
  for (final status in [401, 409, 500]) {
    test('HTTP $status never replays purchase', () async {
      var calls = 0;
      final api = InvestmentPurchaseApi.sale(
        client: MockClient((r) async {
          calls++;
          return http.Response(
            jsonEncode({
              'status': false,
              'message': 'Rejected',
              'data': {'shortfall': 10},
            }),
            status,
          );
        }),
      );
      await expectLater(
        api.create(session, 8, 2),
        throwsA(isA<InvestmentPurchaseFailure>()),
      );
      expect(calls, 1);
      api.dispose();
    });
  }
  testWidgets(
    'OTP verification ends at admin approval, not purchase completion',
    (tester) async {
      var verifies = 0;
      final api = InvestmentPurchaseApi.sale(
        client: MockClient((r) async {
          verifies++;
          expect(r.url.path, '/app/investasi/pengajuan/125/verify-otp');
          return ok({
            'sale': {
              'id': 125,
              'status': {'code': 'menunggu_approval'},
            },
            'otp': {'verified': true},
            'next_action': 'admin_approval',
          });
        }),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: InvestmentPurchaseOtpPage(
            isSale: true,
            session: session,
            api: api,
            item: {
              'id': 125,
              'stock_name': 'KPR',
              'total_lot': 2,
              'total_nilai': 2000000,
              'status': {'code': 'menunggu_verifikasi_otp'},
              'otp': {
                'expires_in': 1800,
                'remaining_attempts': 5,
                'resend_in_seconds': 60,
                'resend_count': 0,
                'resend_limit': 3,
              },
            },
          ),
        ),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField), '001234');
      await tester.ensureVisible(
        find.widgetWithText(BasyaActionButton, 'Verifikasi penjualan'),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(BasyaActionButton, 'Verifikasi penjualan'),
      );
      await tester.pumpAndSettle();
      expect(verifies, 1);
      expect(find.text('OTP berhasil diverifikasi'), findsOneWidget);
      expect(
        find.text(
          'Penjualan menunggu approval admin. Lot berkurang dan hasil penjualan masuk ke Buy Power setelah disetujui.',
        ),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );
  testWidgets('reopen refreshes OTP and resend reads authoritative countdown', (
    tester,
  ) async {
    final calls = <String>[];
    var resent = false;
    Map<String, dynamic> item() => {
      'id': 125,
      'nama': 'KPR',
      'jumlah_lot': 2,
      'nilai': 2000000,
      'status': {'code': 'menunggu_verifikasi_otp'},
      'otp': {
        'remaining_seconds': resent ? 1800 : 0,
        'expired': !resent,
        'remaining_attempts': 5,
        'can_resend': !resent,
        'resend_in_seconds': resent ? 60 : 0,
        'resend_count': resent ? 1 : 0,
        'resend_limit': 3,
      },
    };
    final api = InvestmentPurchaseApi.sale(
      client: MockClient((r) async {
        calls.add(r.method);
        if (r.method == 'POST') {
          expect(r.url.path, '/app/investasi/pengajuan/125/resend-otp');
          resent = true;
          return http.Response('{"status":true}', 200);
        }
        return ok({
          'pengajuan': [item()],
        });
      }),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: InvestmentPurchaseOtpPage(
          isSale: true,
          session: session,
          api: api,
          item: item(),
          refreshOnOpen: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(calls, ['GET']);
    await tester.scrollUntilVisible(
      find.text('Kirim ulang kode'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kirim ulang kode'));
    await tester.pumpAndSettle();
    expect(calls, ['GET', 'POST', 'GET']);
    expect(find.text('Kirim ulang dalam 60 detik'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });
}
