import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:basya_investama/features/multiguna/domain/loan_detail.dart';
import 'package:basya_investama/features/multiguna/presentation/loan_detail_sheet.dart';

void main() {
  testWidgets('installment rows and expanded financing have bounded height', (
    tester,
  ) async {
    final data = LoanDetail(
      jsonDecode(
            File('test/fixtures/multiguna_detail.json').readAsStringSync(),
          )['data']
          as Map,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showLoanDetail(
                context,
                load: () async => data,
                reference: data.reference,
                money: (v) => 'Rp $v',
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final first = find.byKey(const PageStorageKey('loan-installment-7655'));
    expect(tester.getSize(first).height, lessThan(200));
    await tester.tap(find.text('Cicilan ke-1'));
    await tester.pumpAndSettle();
    expect(tester.getSize(first).height, lessThan(650));
    await tester.scrollUntilVisible(
      find.text('Informasi pembiayaan'),
      350,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
      maxScrolls: 25,
    );
    await tester.drag(find.byType(ListView), const Offset(0, -220));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Informasi pembiayaan')); 
    await tester.pumpAndSettle();
    expect(find.text('Plafon'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Lihat dokumen akad'),
      300,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
      maxScrolls: 10,
    );
    expect(find.text('Lihat dokumen akad').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
