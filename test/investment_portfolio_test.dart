import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:basya_investama/features/auth/domain/auth_session.dart';
import 'package:basya_investama/features/investment/data/portfolio_api_client.dart';
import 'package:basya_investama/features/investment/domain/portfolio_data.dart';
import 'package:basya_investama/features/investment/presentation/portfolio_views.dart';

Map<String, dynamic> holding() => {
  'stock_id': 10,
  'nama': 'Proyek Contoh',
  'kode': 'ST10',
  'sub_produk': 'Development',
  'startup': 'Pengelola',
  'lokasi': null,
  'gambar': '',
  'status': 'aktif',
  'project_status': 'open',
  'jumlah_lot': 10,
  'lot_tersedia': 8,
  'harga_per_lot': 1000000,
  'modal': 10000000,
  'profit': 500000,
  'pajak_profit': 50000,
  'profit_bersih': 450000,
  'nilai_saat_ini': 10500000,
  'penjualan_diproses': null,
  'owner': {'investor_id': 1, 'name': 'Investor Contoh'},
};
void main() {
  test(
    'preserves separate holdings for repeated stock and owner in each scope',
    () async {
      for (final scope in ['global', 'personal']) {
        final api = PortfolioApiClient(
          client: MockClient((request) async {
            expect(request.url, PortfolioApiClient.uri);
            expect(request.headers['Authorization'], 'Bearer test');
            return http.Response(
              jsonEncode({
                'status': true,
                'data': {
                  'scope': scope,
                  'currency': 'IDR',
                  'portofolio': [holding(), holding()],
                },
              }),
              200,
            );
          }),
        );
        final result = await api.getPortfolio(
          AuthSession(
            accessToken: 'test',
            tokenType: 'Bearer',
            expiresAt: DateTime(2030),
          ),
        );
        expect(result.items.length, 2);
        expect(result.isGlobal, scope == 'global');
        expect(result.items.first.text('lokasi'), '');
        api.close();
      }
    },
  );
  testWidgets(
    'detail opens sale; validates lots and confirms principal value',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PortfolioCards(
                data: PortfolioData(
                  isGlobal: true,
                  items: [PortfolioItem(holding())],
                ),
                money: (v) => 'Rp $v',
              ),
            ),
          ),
        ),
      );
      await tester.ensureVisible(find.text('Lihat detail portofolio'));
      await tester.tap(find.text('Lihat detail portofolio'));
      await tester.pumpAndSettle();
      expect(find.text('Detail portofolio'), findsOneWidget);
      await tester.tap(find.text('Jual'));
      await tester.pumpAndSettle();
      expect(find.text('Jual investasi'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byType(TextFormField),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(find.byType(TextFormField), '0');
      await tester.pump();
      expect(find.text('Masukkan minimal 1 lot.'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), '9');
      await tester.pump();
      expect(find.text('Jumlah melebihi lot tersedia.'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), '3');
      await tester.scrollUntilVisible(
        find.text('Tinjau penjualan'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Tinjau penjualan'));
      await tester.pumpAndSettle();
      expect(find.text('Konfirmasi penjualan'), findsOneWidget);
      expect(find.text('7 lot'), findsOneWidget);
      expect(find.text('Rp 3000000'), findsWidgets);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Konfirmasi jual'),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('Ubah jumlah'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller!
            .text,
        '3',
      );
      expect(tester.takeException(), isNull);
    },
  );
}
