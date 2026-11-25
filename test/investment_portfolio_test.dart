import 'package:basya_investama/features/investment/data/investment_purchase_api.dart';
import 'package:basya_investama/core/widgets/basya_components.dart';
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
  testWidgets('global portfolio cannot sell another investor holding', (
    tester,
  ) async {
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
    expect(
      tester
          .widget<BasyaActionButton>(
            find.widgetWithText(BasyaActionButton, 'Jual'),
          )
          .onPressed,
      isNull,
    );
  });
  testWidgets('sale uses options available lots and current price', (
    tester,
  ) async {
    final api = InvestmentPurchaseApi.sale(
      client: MockClient((r) async {
        expect(r.url.path, '/app/investasi/penjualan/10/options');
        return http.Response(
          jsonEncode({
            'status': true,
            'data': {
              'stock': {
                'id': 10,
                'proyek': {'nama': 'KPR'},
                'project_status': 'closed',
              },
              'position': {
                'owned_lot': 12,
                'pending_sell_lot': 2,
                'available_lot': 10,
                'harga_per_lot': 2000000,
                'harga_per_lembar': 20000,
                'current_value': 24000000,
                'available_value': 20000000,
              },
              'constraints': {'minimum_lot': 1, 'maximum_lot': 10},
              'eligibility': {'can_sell': true, 'reasons': []},
            },
          }),
          200,
        );
      }),
    );
    addTearDown(api.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: InvestmentSalePage(
          item: PortfolioItem(holding()),
          money: (v) => 'Rp $v',
          session: AuthSession(
            accessToken: 'test',
            tokenType: 'Bearer',
            expiresAt: DateTime(2099),
          ),
          api: api,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byType(TextFormField),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byType(TextFormField), '11');
    final review = find.widgetWithText(BasyaActionButton, 'Tinjau penjualan');
    await tester.ensureVisible(review);
    await tester.pumpAndSettle();
    await tester.tap(review);
    await tester.pumpAndSettle();
    expect(
      find.text('Maksimal 10 lot sesuai lot yang tersedia untuk dijual.'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextFormField), '3');
    await tester.ensureVisible(review);
    await tester.pumpAndSettle();
    await tester.tap(review);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Konfirmasi penjualan'), findsOneWidget);
    expect(find.text('3 lot x Rp 2000000'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Konfirmasi jual'),
          )
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.text('Ubah jumlah'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
      '3',
    );
    expect(tester.takeException(), isNull);
  });
}
