import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:basya_investama/features/home/domain/investor_home_data.dart';
import 'package:basya_investama/features/home/presentation/activity_list.dart';

void main() {
  testWidgets(
    'tapping activity opens scrollable details and preserves masked amounts',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActivityRow(
              activity: const InvestorHomeActivity(
                title: 'Pembelian investasi',
                date: '21 Okt',
                amount: 1200000,
                direction: HomeActivityDirection.outgoing,
                statusLabel: 'Berhasil',
                referenceId: 'SE123',
                stockName: 'Nama investasi yang panjang',
                lots: 120,
                price: 10000,
              ),
              money: (_) => 'Rp ******',
            ),
          ),
        ),
      );
      await tester.tap(find.text('Pembelian investasi'));
      await tester.pumpAndSettle();
      expect(find.text('Detail aktivitas'), findsOneWidget);
      expect(find.text('-Rp ******'), findsNWidgets(2));
      expect(find.textContaining('1.200.000'), findsNothing);
      await tester.ensureVisible(find.text('120 lot'));
      await tester.pumpAndSettle();
      expect(find.text('120 lot'), findsOneWidget);
      expect(find.text('Pajak'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, 1000),
      );
      await tester.pumpAndSettle();
    },
  );
}
