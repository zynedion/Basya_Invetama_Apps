import 'package:basya_investama/features/investment/presentation/investment_purchase_page.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:basya_investama/features/auth/domain/auth_session.dart';
import 'package:basya_investama/features/auth/data/auth_exception.dart';
import 'package:basya_investama/features/investment/data/opportunities_api_client.dart';
import 'package:basya_investama/features/investment/presentation/investment_page.dart';
import 'package:basya_investama/features/investment/presentation/opportunity_detail_sheet.dart';
import 'package:basya_investama/core/widgets/basya_components.dart';
import 'investment_summary_test.dart' show FakeSummary;

void main() {
  final source = File(
    'test/fixtures/investment_opportunities.json',
  ).readAsStringSync();
  final session = AuthSession(
    accessToken: 'test',
    tokenType: 'Bearer',
    expiresAt: DateTime(2030),
  );
  OpportunitiesApiClient client(String body, [int status = 200]) =>
      OpportunitiesApiClient(
        client: MockClient((request) async {
          expect(request.url, OpportunitiesApiClient.uri);
          expect(request.method, 'GET');
          expect(request.headers['Authorization'], 'Bearer test');
          expect(request.url.queryParameters, isEmpty);
          return http.Response(
            body,
            status,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
  test('maps opportunities contract and preserves server allocation', () async {
    final api = client(source);
    addTearDown(api.close);
    final items = await api.getOpportunities(session);
    expect(items.length, 3);
    expect(items.first.id, 10);
    expect(items.first.name, 'SARASA LAND');
    expect(items.first.availableLots, 500);
    expect(items.first.pricePerLot, 1000000);
    expect(items.first.allocatedPercent, 80);
    expect(items[1].allocatedValue, 4554000000);
    expect(items.first.endDate, '9999-12-31');
  });
  test('detail uses ID endpoint and data.peluang object', () async {
    final fixture = jsonDecode(source) as Map;
    final detail = fixture['data']['peluang'][0];
    final api = OpportunitiesApiClient(
      client: MockClient((request) async {
        expect(request.url.path, '/app/investasi/peluang/10');
        expect(request.headers['Authorization'], 'Bearer test');
        return http.Response(
          jsonEncode({
            'status': true,
            'data': {'currency': 'IDR', 'peluang': detail},
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    addTearDown(api.close);
    final item = await api.getOpportunity(session, 10);
    expect(item.name, 'SARASA LAND');
    expect(item.pricePerLot, 1000000);
    expect(item.availableLots, 500);
  });
  testWidgets('purchase uses refreshed detail price and remaining lots', (
    tester,
  ) async {
    final originalApi = client(source);
    final original = (await originalApi.getOpportunities(session)).first;
    originalApi.close();
    final fixture = jsonDecode(source) as Map;
    final detail = fixture['data']['peluang'][0] as Map;
    detail['harga_per_lot'] = 2000000;
    detail['sisa_lot'] = 1;
    final api = OpportunitiesApiClient(
      client: MockClient(
        (request) async => http.Response(
          jsonEncode({
            'status': true,
            'data': {'currency': 'IDR', 'peluang': detail},
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );
    addTearDown(api.close);
    await tester.pumpWidget(
      MaterialApp(
        home: InvestmentPurchasePage(
          opportunity: original,
          buyPower: 10000000,
          session: session,
          detailClient: api,
          summaryGateway: FakeSummary([]),
          money: (v) => 'Rp $v',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Rp 2000000 / lot'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byType(TextFormField),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byType(TextFormField), '2');
    await tester.pump();
    expect(find.text('Maksimal 1 lot tersedia.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '1');
    await tester.pump();
    expect(find.text('Rp 2000000'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
  test('empty list and invalid payloads', () async {
    final api = client(
      jsonEncode({
        'status': true,
        'data': {'currency': 'IDR', 'peluang': []},
      }),
    );
    addTearDown(api.close);
    expect(await api.getOpportunities(session), isEmpty);
    for (final body in [
      '{}',
      '{',
      '{"status":true,"data":{"currency":"IDR","peluang":[{}]}}',
    ]) {
      final bad = client(body);
      await expectLater(
        bad.getOpportunities(session),
        throwsA(isA<AuthException>()),
      );
      bad.close();
    }
    final expired = client('{}', 401);
    await expectLater(
      expired.getOpportunities(session),
      throwsA(
        isA<AuthException>().having(
          (e) => e.type,
          'type',
          AuthFailureType.invalidCredentials,
        ),
      ),
    );
    expired.close();
  });
  test('HTML description is inert readable text', () {
    expect(
      opportunityDescription(
        '<p>Hello &amp; <b>world</b></p><script>alert(1)</script><p>&#65;<br>next</p>',
      ),
      'Hello & world\nA\nnext',
    );
  });
  testWidgets('live card opens scrollable detail with fixed buy action', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = client(source);
    addTearDown(api.close);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InvestmentPage(
            session: session,
            summaryGateway: FakeSummary([]),
            opportunitiesGateway: api,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final detail = find.text('Lihat detail investasi').first;
    await tester.scrollUntilVisible(
      find.text('Lihat detail investasi'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(detail);
    await tester.pumpAndSettle();
    expect(find.text('Detail investasi'), findsOneWidget);
    final hint = find.byKey(const ValueKey('opportunity-more-info'));
    final scroll = tester
        .widget<SingleChildScrollView>(
          find.byKey(const ValueKey('opportunity-detail-scroll')),
        )
        .controller!;
    Finder opacity() =>
        find.ancestor(of: hint, matching: find.byType(AnimatedOpacity)).first;
    expect(tester.widget<AnimatedOpacity>(opacity()).opacity, 1);
    await tester.tap(hint);
    await tester.pumpAndSettle();
    expect(scroll.offset, greaterThan(0));
    scroll.jumpTo(scroll.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedOpacity>(opacity()).opacity, 0);
    scroll.jumpTo(0);
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedOpacity>(opacity()).opacity, 1);

    expect(find.text('Beli'), findsOneWidget);
    final buy = find.byWidgetPredicate(
      (w) => w is BasyaActionButton && w.label == 'Beli',
    );
    expect(tester.widget<BasyaActionButton>(buy).onPressed, isNotNull);
    final before = tester.getRect(buy);
    await tester.drag(
      find.byType(SingleChildScrollView).last,
      const Offset(0, -1600),
    );
    await tester.pumpAndSettle();
    expect(tester.getRect(buy), before);
    expect(find.text('Tidak ditentukan'), findsOneWidget);
    await tester.tap(buy);
    await tester.pumpAndSettle();
    expect(find.text('Beli investasi'), findsOneWidget);
    expect(find.text('Informasi investasi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
