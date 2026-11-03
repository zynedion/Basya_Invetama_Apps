import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:basya_investama/features/auth/domain/auth_session.dart';
import 'package:basya_investama/features/home/domain/activities_gateway.dart';
import 'package:basya_investama/features/home/domain/investor_home_data.dart';
import 'package:basya_investama/features/home/presentation/activities_feed.dart';

class Pages implements ActivitiesGateway {
  final calls = <int>[];
  final pending = <int, Completer<List<InvestorHomeActivity>>>{};
  @override
  Future<List<InvestorHomeActivity>> getActivities(
    AuthSession session, {
    int? limit,
    int? page,
    int? perPage,
  }) {
    expect(limit, isNull);
    expect(perPage, 20);
    calls.add(page!);
    return (pending[page] = Completer()).future;
  }
}

List<InvestorHomeActivity> rows(int start, int count) => List.generate(
  count,
  (i) => InvestorHomeActivity(
    id: '${start + i}',
    title: 'Item ${start + i}',
    date: '3 Nov',
    amount: i,
    direction: HomeActivityDirection.incoming,
  ),
);

class MetadataPages extends Pages implements PaginatedActivitiesGateway {
  bool next = false;
  @override
  Future<ActivitiesPageData> getActivitiesPage(
    AuthSession session, {
    required int page,
    required int perPage,
  }) async {
    final items = await getActivities(session, page: page, perPage: perPage);
    return ActivitiesPageData(
      items: items,
      page: page,
      perPage: perPage,
      totalItems: 40,
      totalPages: 2,
      hasPrevious: page > 1,
      hasNext: next,
    );
  }
}

void main() {
  testWidgets(
    'scroll loads once, retry keeps rows, refresh rejects old page and resets',
    (tester) async {
      final api = Pages();
      final key = GlobalKey<ActivitiesFeedState>();
      final session = AuthSession(
        accessToken: 'test',
        tokenType: 'Bearer',
        expiresAt: DateTime(2030),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActivitiesFeed(
              key: key,
              session: session,
              gateway: api,
              money: (v) => '$v',
              scrollable: true,
            ),
          ),
        ),
      );
      api.pending[1]!.complete(rows(0, 20));
      await tester.pumpAndSettle();
      final scroll = tester.widget<ListView>(find.byType(ListView)).controller!;
      scroll.jumpTo(scroll.position.maxScrollExtent);
      await tester.pump();
      expect(api.calls, [1, 2]);
      scroll.jumpTo(scroll.position.maxScrollExtent);
      await tester.pump();
      expect(api.calls, [1, 2]);
      api.pending[2]!.completeError(Exception('offline'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Coba lagi'));
      await tester.tap(find.text('Coba lagi'));
      await tester.pump();
      expect(api.calls, [1, 2, 2]);
      final oldPage = api.pending[2]!;
      final refreshed = key.currentState!.refresh();
      api.pending[1]!.complete(rows(100, 2));
      await refreshed;
      oldPage.complete(rows(20, 20));
      await tester.pumpAndSettle();
      scroll.jumpTo(0);
      await tester.pumpAndSettle();
      expect(find.text('Item 100'), findsOneWidget);
      expect(find.text('Item 20'), findsNothing);
      expect(api.calls, [1, 2, 2, 1]);
    },
  );
  testWidgets('next page appends unique IDs and short page stops loading', (
    tester,
  ) async {
    final api = Pages();
    final session = AuthSession(
      accessToken: 'test',
      tokenType: 'Bearer',
      expiresAt: DateTime(2030),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActivitiesFeed(
            session: session,
            gateway: api,
            money: (v) => '$v',
            scrollable: true,
          ),
        ),
      ),
    );
    api.pending[1]!.complete(rows(0, 20));
    await tester.pumpAndSettle();
    final scroll = tester.widget<ListView>(find.byType(ListView)).controller!;
    scroll.jumpTo(scroll.position.maxScrollExtent);
    await tester.pump();
    api.pending[2]!.complete(rows(19, 3));
    await tester.pumpAndSettle();
    scroll.jumpTo(scroll.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(find.text('Item 19'), findsOneWidget);
    expect(find.text('Item 21'), findsOneWidget);
    expect(api.calls, [1, 2]);
    scroll.jumpTo(0);
    await tester.pumpAndSettle();
    expect(find.text('Item 0'), findsOneWidget);
  });
  testWidgets('has_next false stops on a full page', (tester) async {
    final api = MetadataPages();
    final session = AuthSession(
      accessToken: 'test',
      tokenType: 'Bearer',
      expiresAt: DateTime(2030),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActivitiesFeed(
            session: session,
            gateway: api,
            money: (v) => '$v',
            scrollable: true,
          ),
        ),
      ),
    );
    api.pending[1]!.complete(rows(0, 20));
    await tester.pumpAndSettle();
    final controller = tester
        .widget<ListView>(find.byType(ListView))
        .controller!;
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(api.calls, [1]);
  });
  testWidgets('has_next true continues even after a short page', (
    tester,
  ) async {
    final api = MetadataPages()..next = true;
    final session = AuthSession(
      accessToken: 'test',
      tokenType: 'Bearer',
      expiresAt: DateTime(2030),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActivitiesFeed(
            session: session,
            gateway: api,
            money: (v) => '$v',
            scrollable: true,
          ),
        ),
      ),
    );
    api.pending[1]!.complete(rows(0, 1));
    await tester.pump();
    await tester.pump();
    expect(api.calls, [1, 2]);
    api.next = false;
    api.pending[2]!.complete(rows(1, 1));
    await tester.pumpAndSettle();
    expect(find.text('Item 1'), findsOneWidget);
    expect(api.calls, [1, 2]);
  });
}
