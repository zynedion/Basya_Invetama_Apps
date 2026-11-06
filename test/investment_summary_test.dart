import 'package:basya_investama/features/auth/domain/auth_session.dart';
import 'package:basya_investama/features/home/domain/home_summary.dart';
import 'package:basya_investama/features/home/domain/home_summary_gateway.dart';
import 'package:basya_investama/features/investment/presentation/investment_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeSummary implements HomeSummaryGateway {
  FakeSummary(this.points);
  final List<InvestmentPerformancePoint> points;
  @override
  Future<HomeSummary> getSummary(AuthSession session) async => HomeSummary(
    scope: HomeSummaryScope.global,
    currency: 'IDR',
    year: 2026,
    month: 11,
    totalBalance: 305162833,
    buyPower: 243756976,
    voluntarySavings: 7555857,
    principalSavings: 20650000,
    mandatorySavings: 33200000,
    investedFunds: 20998000000,
    monthlyProfit: 10815869,
    accumulatedProfit: 2278653802,
    totalInvestmentValue: 23276653802,
    performanceType: 'profit_bruto',
    performance: points,
  );
}

void main() {
  testWidgets(
    'entrance waits for visibility and replays when returning to tab',
    (tester) async {
      var active = false;
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return Scaffold(
                body: IndexedStack(
                  index: active ? 1 : 0,
                  children: [
                    const SizedBox(),
                    TickerMode(enabled: active, child: const InvestmentPage()),
                  ],
                ),
              );
            },
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 2));
      final bar = find.byKey(
        const ValueKey('investment-bar-height-5'),
        skipOffstage: false,
      );
      double height() => tester.widget<Transform>(bar).transform.entry(1, 1);
      expect(height(), 0);
      update(() => active = true);
      await tester.pump();
      expect(height(), 0);
      await tester.pump(const Duration(milliseconds: 300));
      expect(height(), inExclusiveRange(0, 1));
      await tester.pumpAndSettle();
      expect(height(), 1);
      update(() => active = false);
      await tester.pump();
      update(() => active = true);
      await tester.pump();
      expect(height(), 0);
      await tester.pump(const Duration(milliseconds: 300));
      expect(height(), inExclusiveRange(0, .4));
      await tester.pumpAndSettle();
      expect(height(), 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('bars grow once and stay full when selected', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: InvestmentPage())),
    );
    final bar = find.byKey(const ValueKey('investment-bar-height-5'));
    double height() => tester.widget<Transform>(bar).transform.entry(1, 1);
    expect(height(), 0);
    await tester.pump(const Duration(milliseconds: 300));
    expect(height(), greaterThan(0));
    expect(height(), lessThan(1));
    await tester.pumpAndSettle();
    expect(height(), 1);
    await tester.tap(find.byKey(const ValueKey('investment-bar-5')));
    await tester.pump();
    expect(height(), 1);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('reduced motion shows final bar heights immediately', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(body: InvestmentPage()),
        ),
      ),
    );
    expect(
      tester
          .widget<Transform>(
            find.byKey(const ValueKey('investment-bar-height-5')),
          )
          .transform
          .entry(1, 1),
      1,
    );
    expect(tester.takeException(), isNull);
  });

  for (final profit in <int?>[10815869, 0, null]) {
    testWidgets('summary renders at narrow width with profit $profit', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InvestmentPage(
              session: AuthSession(
                accessToken: 'test',
                tokenType: 'Bearer',
                expiresAt: DateTime(2030),
              ),
              summaryGateway: FakeSummary(
                profit == null
                    ? []
                    : [
                        InvestmentPerformancePoint(
                          year: 2026,
                          month: 11,
                          label: 'Nov',
                          profit: profit,
                        ),
                      ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Rp 23.276.653.802'), findsOneWidget);
      expect(find.text('Profit bruto bulanan'), findsOneWidget);
      expect(
        find.text(
          profit == null ? 'Data performa belum tersedia.' : 'Nov 2026',
        ),
        findsOneWidget,
      );
      if (profit != null) {
        final plot = find.byKey(const ValueKey('investment-chart-plot'));
        final before = tester.getRect(plot);
        final title = tester.getRect(find.text('Profit bruto bulanan'));
        expect(before.top - title.bottom, lessThanOrEqualTo(12));
        await tester.tap(find.byKey(const ValueKey('investment-bar-0')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));
        final transformFinder = find.descendant(
          of: find.byKey(const ValueKey('investment-bar-0')),
          matching: find.byType(Transform),
        );
        expect(
          tester.widget<Transform>(transformFinder).transform.entry(0, 0),
          greaterThan(1),
        );
        await tester.pumpAndSettle();
        expect(
          tester.widget<Transform>(transformFinder).transform.entry(0, 0),
          1,
        );
        expect(tester.getRect(plot), before);
        expect(
          tester
              .getRect(find.byKey(const ValueKey('investment-chart-detail')))
              .bottom,
          lessThan(before.top),
        );
        final detail = tester.widget<Text>(
          find.byKey(const ValueKey('investment-chart-detail')),
        );
        expect(detail.data, contains(profit == 0 ? 'Rp 0' : 'Rp 10.815.869'));
        await tester.tap(find.byTooltip('Sembunyikan nilai'));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('investment-chart-detail')),
          findsNothing,
        );
        await tester.tap(find.byKey(const ValueKey('investment-bar-0')));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<Text>(
                find.byKey(const ValueKey('investment-chart-detail')),
              )
              .data,
          isNot(contains('Rp 10.815.869')),
        );
      }
      expect(tester.takeException(), isNull);
    });
  }
}
