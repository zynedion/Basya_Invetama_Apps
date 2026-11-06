import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:basya_investama/features/investment/domain/investment_overview_data.dart';
import 'package:basya_investama/features/investment/presentation/investment_purchase_page.dart';

void main() {
  const product = InvestmentOpportunity(
    name: 'SARASA LAND',
    category: 'Development',
    location: 'Sukabumi',
    pricePerLot: 1000000,
    availableLots: 5,
    totalLots: 2500,
    status: 'available',
    projectStatus: 'open',
  );
  testWidgets('validates quantity, stock and balance before confirmation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: InvestmentPurchasePage(
          opportunity: product,
          buyPower: 3000000,
          money: (v) => 'Rp $v',
        ),
      ),
    );
    await tester.scrollUntilVisible(
      find.text('Tinjau pembelian'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Tinjau pembelian'));
    await tester.pumpAndSettle();
    expect(find.text('Masukkan minimal 1 lot.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '6');
    await tester.pump();
    expect(find.text('Maksimal 5 lot tersedia.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '4');
    await tester.pump();
    expect(find.text('Buy power tidak mencukupi.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '2');
    await tester.pump();
    expect(find.text('Rp 2000000'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Tinjau pembelian'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Tinjau pembelian'));
    await tester.pumpAndSettle();
    expect(find.text('Konfirmasi pembelian'), findsOneWidget);
    expect(find.text('2 lot'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Konfirmasi beli'),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('Ubah jumlah'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
      '2',
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('missing personal balance cannot confirm', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: InvestmentPurchasePage(
          opportunity: product,
          buyPower: null,
          money: (v) => 'Rp $v',
        ),
      ),
    );
    await tester.scrollUntilVisible(
      find.byType(TextFormField),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byType(TextFormField), '1');
    await tester.ensureVisible(find.text('Tinjau pembelian'));
    await tester.scrollUntilVisible(
      find.text('Tinjau pembelian'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Tinjau pembelian'));
    await tester.pumpAndSettle();
    expect(find.text('Buy power belum tersedia.'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });
}
