import 'package:basya_investama/core/theme/app_theme.dart';
import 'package:basya_investama/features/auth/domain/auth_session.dart';
import 'package:basya_investama/features/home/domain/home_summary.dart';
import 'package:basya_investama/features/home/domain/home_summary_gateway.dart';
import 'package:basya_investama/features/home/presentation/investor_home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final session = AuthSession(
    accessToken: 'token',
    tokenType: 'Bearer',
    expiresAt: DateTime.utc(2026, 9, 18),
  );

  testWidgets('global summary keeps investor and non-investor preview', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: InvestorHomePage(
          session: session,
          summaryGateway: _FakeSummaryGateway(_summary(global: true)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ringkasan global'), findsOneWidget);
    expect(find.text('Rp 655.132.334'), findsOneWidget);
    expect(find.text('Investor'), findsOneWidget);
    expect(find.text('Non-investor'), findsOneWidget);

    await tester.tap(find.text('Non-investor'));
    await tester.pumpAndSettle();
    expect(find.text('Rp 595.648.197'), findsOneWidget);
  });

  testWidgets('personal summary hides development audience switch', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: InvestorHomePage(
          session: session,
          summaryGateway: _FakeSummaryGateway(_summary(global: false)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ringkasan global'), findsNothing);
    expect(find.text('Investor'), findsNothing);
    expect(find.text('Non-investor'), findsNothing);
  });
}

HomeSummary _summary({required bool global}) => HomeSummary(
  scope: global ? HomeSummaryScope.global : HomeSummaryScope.personal,
  currency: 'IDR',
  year: 2026,
  month: 9,
  totalBalance: 655132334,
  buyPower: 59484137,
  voluntarySavings: 542148197,
  principalSavings: 21350000,
  mandatorySavings: 32150000,
  investedFunds: 20298000000,
  monthlyProfit: 26133977,
  accumulatedProfit: 2009462870,
);

class _FakeSummaryGateway implements HomeSummaryGateway {
  const _FakeSummaryGateway(this.summary);

  final HomeSummary summary;

  @override
  Future<HomeSummary> getSummary(AuthSession session) async => summary;
}
