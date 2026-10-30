import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:basya_investama/features/auth/domain/auth_session.dart';
import 'package:basya_investama/features/savings/domain/savings_gateway.dart';
import 'package:basya_investama/features/savings/domain/savings_overview_data.dart';
import 'package:basya_investama/features/savings/presentation/savings_page.dart';
import 'package:basya_investama/features/savings/presentation/savings_history_page.dart';

class FakeSavings implements SavingsGateway {
  final calls = <(SavingsType?, int?)>[];
  bool fail = false;
  @override
  Future<SavingsOverviewData> getSavings(
    AuthSession session, {
    SavingsType? type,
    int? limit,
  }) async {
    calls.add((type, limit));
    if (fail) throw Exception();
    return SavingsOverviewData(
      voluntarySavings: 899,
      principalSavings: 350000,
      mandatorySavings: 600000,
      transactions: List.generate(
        7,
        (i) => SavingsTransaction(
          title: 'Transaction $i',
          date: '12 Okt 2026',
          status: 'Berhasil',
          amount: 50000,
          direction: SavingsTransactionDirection.incoming,
        ),
      ),
    );
  }
}

void main() {
  final session = AuthSession(
    accessToken: 'test',
    tokenType: 'Bearer',
    expiresAt: DateTime(2030),
  );
  testWidgets(
    'overview shows API balances and missing SHU; history requests filters without limit',
    (tester) async {
      final gateway = FakeSavings();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SavingsPage(session: session, gateway: gateway),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(gateway.calls, [(null, 5)]);
      expect(find.text('Rp 899'), findsOneWidget);
      expect(find.text('Perbarui'), findsNothing);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 400));
      await tester.pumpAndSettle();
      expect(gateway.calls.length, 2);

      await tester.scrollUntilVisible(find.text('Belum tersedia'), 200);
      expect(find.text('Belum tersedia'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Lihat semua'), 200);
      await tester.tap(find.text('Lihat semua'));
      await tester.pumpAndSettle();
      expect(find.byType(SavingsHistoryPage), findsOneWidget);
      expect(gateway.calls.last, (null, null));
      await tester.tap(find.text('Wajib'));
      await tester.pumpAndSettle();
      expect(gateway.calls.last, (SavingsType.wajib, null));
      final beforeRefresh = gateway.calls.length;
      await tester.drag(find.byType(ListView), const Offset(0, 400));
      await tester.pumpAndSettle();
      expect(gateway.calls.length, beforeRefresh + 1);
      expect(gateway.calls.last, (SavingsType.wajib, null));
      final filterScroll = find.byWidgetPredicate(
        (w) =>
            w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
      );
      expect(filterScroll, findsOneWidget);
      final semuaY = tester
          .getTopLeft(find.widgetWithText(ChoiceChip, 'Semua'))
          .dy;
      final sukarelaY = tester
          .getTopLeft(find.widgetWithText(ChoiceChip, 'Sukarela'))
          .dy;
      expect(semuaY, sukarelaY);

      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'failed request does not expose demo balance and retry loads real balance',
    (tester) async {
      final gateway = FakeSavings()..fail = true;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SavingsPage(session: session, gateway: gateway),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Rp 12.500.000'), findsNothing);
      await tester.scrollUntilVisible(find.text('Coba lagi'), 150);
      gateway.fail = false;
      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();
      expect(gateway.calls.length, 2);
      expect(tester.takeException(), isNull);
    },
  );
}
