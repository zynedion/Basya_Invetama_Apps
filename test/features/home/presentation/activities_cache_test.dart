import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:basya_investama/features/auth/domain/auth_session.dart';
import 'package:basya_investama/features/auth/domain/session_memory_cache.dart';
import 'package:basya_investama/features/home/domain/activities_gateway.dart';
import 'package:basya_investama/features/home/domain/investor_home_data.dart';
import 'package:basya_investama/features/home/presentation/activities_feed.dart';

class PendingActivities implements ActivitiesGateway {
  Completer<List<InvestorHomeActivity>> pending = Completer();
  @override
  Future<List<InvestorHomeActivity>> getActivities(
    AuthSession session, {
    int? limit,
    int? page,
    int? perPage,
  }) => pending.future;
}

const row = InvestorHomeActivity(
  title: 'Cached activity',
  date: '1 Nov',
  amount: 100,
  direction: HomeActivityDirection.incoming,
);
void main() {
  test(
    'cache separates limits and sessions; old requests cannot restore cleared data',
    () {
      final a = SessionMemoryCache();
      final b = SessionMemoryCache();
      final ticket = a.begin('activities:page1:20');
      a.write('activities:page1:20', [row], ticket);
      expect(a.read<List<InvestorHomeActivity>>('activities:page1:20'), [row]);
      expect(a.read<List<InvestorHomeActivity>>('activities:5'), isNull);
      expect(b.read<List<InvestorHomeActivity>>('activities:page1:20'), isNull);
      a.clear();
      expect(a.write('activities:page1:20', [row], ticket), isFalse);
      expect(a.read<List<InvestorHomeActivity>>('activities:page1:20'), isNull);
    },
  );
  testWidgets(
    'cached rows remain while revalidating, survive failure and empty success replaces them',
    (tester) async {
      final cache = SessionMemoryCache();
      cache.write('activities:page1:20', <InvestorHomeActivity>[
        row,
      ], cache.begin('activities:page1:20'));
      final session = AuthSession(
        accessToken: 'test',
        tokenType: 'Bearer',
        expiresAt: DateTime(2030),
        cache: cache,
      );
      final gateway = PendingActivities();
      final key = GlobalKey<ActivitiesFeedState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActivitiesFeed(
              key: key,
              session: session,
              gateway: gateway,
              scrollable: true,
              money: (v) => 'Rp $v',
            ),
          ),
        ),
      );
      expect(find.text('Cached activity'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      gateway.pending.completeError(Exception('offline'));
      await tester.pumpAndSettle();
      expect(find.text('Cached activity'), findsOneWidget);
      expect(
        find.text('Menampilkan data terakhir; pembaruan gagal.'),
        findsOneWidget,
      );
      gateway.pending = Completer();
      final refresh = key.currentState!.refresh();
      await tester.pump();
      expect(find.text('Cached activity'), findsOneWidget);
      gateway.pending.complete([]);
      await refresh;
      await tester.pumpAndSettle();
      expect(find.text('Cached activity'), findsNothing);
      expect(find.text('Belum ada aktivitas.'), findsOneWidget);
      expect(
        cache.read<List<InvestorHomeActivity>>('activities:page1:20'),
        isEmpty,
      );
    },
  );
  testWidgets(
    'clearing session removes visible cache and rejects in-flight result',
    (tester) async {
      final cache = SessionMemoryCache();
      cache.write('activities:page1:20', <InvestorHomeActivity>[
        row,
      ], cache.begin('activities:page1:20'));
      final session = AuthSession(
        accessToken: 'test',
        tokenType: 'Bearer',
        expiresAt: DateTime(2030),
        cache: cache,
      );
      final gateway = PendingActivities();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActivitiesFeed(
              session: session,
              gateway: gateway,
              scrollable: true,
              money: (v) => 'Rp $v',
            ),
          ),
        ),
      );
      cache.clear();
      await tester.pump();
      expect(find.text('Cached activity'), findsNothing);
      gateway.pending.complete([row]);
      await tester.pumpAndSettle();
      expect(find.text('Cached activity'), findsNothing);
      expect(
        cache.read<List<InvestorHomeActivity>>('activities:page1:20'),
        isNull,
      );
    },
  );
}
