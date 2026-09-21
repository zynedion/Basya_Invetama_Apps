import 'package:basya_investama/core/theme/app_theme.dart';
import 'package:basya_investama/features/auth/domain/auth_session.dart';
import 'package:basya_investama/features/home/presentation/investor_home_page.dart';
import 'package:basya_investama/features/multiguna/domain/multiguna_gateway.dart';
import 'package:basya_investama/features/multiguna/domain/multiguna_overview_data.dart';
import 'package:basya_investama/features/navigation/presentation/main_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final session = AuthSession(
    accessToken: 'test-token',
    tokenType: 'Bearer',
    expiresAt: DateTime.utc(2026, 9, 22),
  );

  testWidgets('Home hides Multiguna card when member has no active loan', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MainContainer(
          session: session,
          multigunaGateway: const _FakeMultigunaGateway(
            MultigunaOverviewData(
              accessible: true,
              currency: 'IDR',
              hasMultiguna: false,
              totalContracts: 0,
              totalInstallment: 0,
              totalObligation: 0,
              loans: [],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('home-multiguna-card')), findsNothing);

    await tester.tap(find.byTooltip('Multiguna'));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada pinjaman aktif'), findsOneWidget);
  });

  testWidgets('Home hides Multiguna card when account is forbidden', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MainContainer(
          session: session,
          multigunaGateway: const _FakeMultigunaGateway(
            MultigunaOverviewData.unavailable,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('home-multiguna-card')), findsNothing);

    await tester.tap(find.byTooltip('Multiguna'));
    await tester.pumpAndSettle();
    expect(find.text('Multiguna tidak tersedia'), findsOneWidget);
  });

  testWidgets('Home shows Multiguna card when an active contract exists', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MainContainer(
          session: session,
          multigunaGateway: _FakeMultigunaGateway(MultigunaOverviewData.demo),
          audience: HomeAudience.investor,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('home-multiguna-card')), findsOneWidget);
    expect(find.text('Rp 625.000'), findsOneWidget);
  });
}

class _FakeMultigunaGateway implements MultigunaGateway {
  const _FakeMultigunaGateway(this.data);

  final MultigunaOverviewData data;

  @override
  Future<MultigunaOverviewData> getOverview(AuthSession session) async => data;
}
