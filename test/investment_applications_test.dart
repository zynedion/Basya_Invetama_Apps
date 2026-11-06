import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:basya_investama/features/auth/domain/auth_session.dart';
import 'package:basya_investama/features/investment/data/applications_api_client.dart';
import 'package:basya_investama/features/investment/presentation/applications_view.dart';

Map<String, dynamic> entry(String code) => {
  'id': 1,
  'stock_id': 10,
  'nama': 'Proyek contoh',
  'order_id': 'SE123',
  'kode_stock': 'ST123',
  'jenis': 'pembelian',
  'jumlah_lot': 3,
  'harga_per_lot': 1000000,
  'harga_per_lembar': 10000,
  'nilai': 3000000,
  'diajukan_pada': '2026-11-04 09:00:00',
  'status': {'code': code, 'label': code},
  'otp': {
    'available': true,
    'verified': false,
    'expired': false,
    'expires_at': '2026-11-04 09:30:00',
  },
  'owner': {'name': 'Investor contoh'},
};
void main() {
  final session = AuthSession(
    accessToken: 'test',
    tokenType: 'Bearer',
    expiresAt: DateTime(2030),
  );
  test('preview limit and unlimited filtered list follow contract', () async {
    final queries = <Map<String, String>>[];
    final api = ApplicationsApiClient(
      client: MockClient((r) async {
        expect(r.url.path, '/app/investasi/pengajuan');
        expect(r.headers['Authorization'], 'Bearer test');
        queries.add(r.url.queryParameters);
        return http.Response(
          jsonEncode({
            'status': true,
            'data': {
              'scope': 'global',
              'currency': 'IDR',
              'jumlah_pengajuan': 8,
              'pengajuan': [entry('menunggu_approval')],
            },
          }),
          200,
        );
      }),
    );
    final result = await api.getApplications(session, limit: 3);
    expect(result.total, 8);
    expect(result.global, true);
    expect(result.items.single.owner, 'Investor contoh');
    await api.getApplications(session, type: 'penjualan');
    expect(queries, [
      {'limit': '3'},
      {'type': 'penjualan'},
    ]);
    api.close();
  });
  testWidgets('status colors distinct and list filter refreshes', (
    tester,
  ) async {
    final requests = <String?>[];
    final api = ApplicationsApiClient(
      client: MockClient((r) async {
        requests.add(r.url.queryParameters['type']);
        return http.Response(
          jsonEncode({
            'status': true,
            'data': {
              'scope': 'personal',
              'currency': 'IDR',
              'jumlah_pengajuan': 3,
              'pengajuan': [
                for (final code in [
                  'menunggu_verifikasi_otp',
                  'menunggu_approval',
                  'otp_kedaluwarsa',
                ])
                  entry(code),
              ],
            },
          }),
          200,
        );
      }),
    );
    addTearDown(api.close);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ApplicationsView(
            session: session,
            money: (v) => 'Rp $v',
            gateway: api,
            preview: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final colors = <Color?>{};
    for (final code in [
      'menunggu_verifikasi_otp',
      'menunggu_approval',
      'otp_kedaluwarsa',
    ]) {
      await tester.scrollUntilVisible(
        find.text(code),
        150,
        scrollable: find.byType(Scrollable).last,
      );
      colors.add(tester.widget<Text>(find.text(code)).style!.color);
    }
    expect(colors.length, 3);
    await tester.tap(find.text('otp_kedaluwarsa'));
    await tester.pumpAndSettle();
    expect(find.text('Detail pengajuan'), findsOneWidget);
    await tester.tap(find.byTooltip('Tutup'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, 1200));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Penjualan'));
    await tester.pumpAndSettle();
    expect(requests.last, 'penjualan');
    expect(tester.takeException(), isNull);
  });
}
