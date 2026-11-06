import 'package:basya_investama/features/multiguna/presentation/multiguna_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:basya_investama/features/multiguna/domain/installment_schedule.dart';
import 'package:basya_investama/features/multiguna/domain/multiguna_overview_data.dart';
import 'package:basya_investama/features/multiguna/presentation/installment_calendar.dart';
import 'package:basya_investama/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

MultigunaLoan loan({
  int day = 20,
  DateTime? next,
  DateTime? end,
  int total = 17,
}) => MultigunaLoan(
  contractNumber: 'L260721025837627',
  startDate: DateTime(2026, 8, 1),
  endDate: end ?? DateTime(2028, 1, 20),
  installmentAmount: 295294,
  totalPayment: 590588,
  remainingBalance: 4429412,
  dueDay: day,
  nextDueDate: next ?? DateTime(2026, 10, 20),
  paidInstallments: 2,
  totalInstallments: total,
  nextInstallmentNumber: 3,
  collectibilityValue: -1,
  collectibilityLabel: 'COL -1',
  collectibilityCategory: 'warning',
  paymentStatusCode: 'overdue',
  paymentStatusLabel: 'Cicilan Belum Dibayar',
  arrearsMonths: 1,
  arrearsAmount: 295294,
);
void main() {
  testWidgets(
    'compact page fits narrow screen and keeps overdue below calendar',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 900),
              textScaler: TextScaler.linear(1.3),
            ),
            child: Scaffold(
              body: MultigunaPage(data: MultigunaOverviewData.demo),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('selected-installment-heading')),
        findsNothing,
      );
      final overdue = find.byKey(const ValueKey('overdue-MG-2025-004'));
      await tester.scrollUntilVisible(overdue, 150);
      expect(
        tester.getTopLeft(overdue).dy,
        greaterThan(tester.getTopLeft(find.byType(InstallmentCalendar)).dy),
      );
      await tester.scrollUntilVisible(
        find.text('8 dari 24 cicilan dibayar'),
        150,
      );
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'API date is authoritative; projections stop at earlier count or end date',
    () {
      final loans = [loan()];
      final anchor = installmentsOn(loans, DateTime(2026, 10, 20)).single;
      expect(anchor.estimated, isFalse);
      expect(anchor.overdue, isTrue);
      final future = installmentsOn(loans, DateTime(2026, 11, 20)).single;
      expect(future.number, 4);
      expect(future.estimated, isTrue);
      expect(future.overdue, isFalse);
      expect(installmentsOn(loans, DateTime(2026, 9, 20)), isEmpty);
      expect(installmentsOn(loans, DateTime(2027, 12, 20)).single.number, 17);
      expect(installmentsOn(loans, DateTime(2028, 1, 20)), isEmpty);
      expect(
        installmentsOn([
          loan(end: DateTime(2026, 11, 19)),
        ], DateTime(2026, 11, 20)),
        isEmpty,
      );
    },
  );
  test('month-end projection clamps date and supports multiple contracts', () {
    final item = loan(day: 31, next: DateTime(2027, 1, 31));
    expect(
      installmentsOn([item], DateTime(2027, 2, 28)).single.estimated,
      isTrue,
    );
    expect(installmentsOn([item], DateTime(2027, 3, 31)).single.number, 5);
    expect(
      installmentsOn([loan(), loan()], DateTime(2026, 10, 20)),
      hasLength(2),
    );
  });
  testWidgets(
    'default has no detail; marked date opens detail and empty date clears it',
    (tester) async {
      final loans = [loan()];
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              child: InstallmentCalendar(
                loans: loans,
                money: (v) => 'Rp $v',
                onPay: (_) {},
              ),
            ),
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey('selected-installment-heading')),
        findsNothing,
      );
      await tester.tap(
        find.byKey(const ValueKey('installment-day-2026-10-20')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('selected-installment-heading')),
        findsOneWidget,
      );
      expect(find.text('Bayar'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('installment-day-2026-10-21')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('selected-installment-heading')),
        findsNothing,
      );
      await tester.tap(find.text('Lihat sebulan'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('installment-day-2026-10-1')),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Bulan berikutnya'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('installment-day-2026-11-20')),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Perkiraan jadwal'), findsOneWidget);
      expect(find.text('Bayar'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
