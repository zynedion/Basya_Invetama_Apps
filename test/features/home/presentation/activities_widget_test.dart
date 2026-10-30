import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:basya_investama/features/auth/domain/auth_session.dart';
import 'package:basya_investama/features/home/domain/activities_gateway.dart';
import 'package:basya_investama/features/home/domain/investor_home_data.dart';
import 'package:basya_investama/features/home/presentation/activities_feed.dart';
import 'package:basya_investama/features/home/presentation/activities_page.dart';

class FakeActivities implements ActivitiesGateway {
  bool fail = false;
  final requestedLimits = <int?>[];
  @override
  Future<List<InvestorHomeActivity>> getActivities(
    AuthSession session, {
    int? limit,
  }) async {
    requestedLimits.add(limit);
    if (fail) throw Exception();
    return List.generate(
      7,
      (i) => InvestorHomeActivity(
        title: 'Activity $i',
        date: '21 Okt',
        amount: i,
        direction: HomeActivityDirection.incoming,
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
  testWidgets('home feed caps five; full page shows all returned items', (
    tester,
  ) async {
    final gateway = FakeActivities();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActivitiesFeed(
            session: session,
            gateway: gateway,
            money: (v) => 'Rp $v',
            maxRows: 5,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Activity 4'), findsOneWidget);
    expect(find.text('Activity 5'), findsNothing);
    await tester.pumpWidget(
      MaterialApp(
        home: ActivitiesPage(
          session: session,
          gateway: gateway,
          money: (v) => 'Rp $v',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Activity 6'), findsOneWidget);
    expect(gateway.requestedLimits, [5, null]);
    expect(find.text('Perbarui'), findsNothing);
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, 400),
    );
    await tester.pumpAndSettle();
    expect(gateway.requestedLimits, [5, null, null]);

    expect(tester.takeException(), isNull);
  });
  testWidgets('error can retry without showing preview data', (tester) async {
    final gateway = FakeActivities()..fail = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActivitiesFeed(
            session: session,
            gateway: gateway,
            money: (v) => 'Rp $v',
            maxRows: 5,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Coba lagi'), findsOneWidget);
    expect(find.text('Activity 0'), findsNothing);
    gateway.fail = false;
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(find.text('Activity 0'), findsOneWidget);
  });
}
