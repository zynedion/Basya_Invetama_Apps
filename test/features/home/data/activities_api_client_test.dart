import 'dart:convert';
import 'package:basya_investama/features/auth/data/auth_exception.dart';
import 'package:basya_investama/features/auth/domain/auth_session.dart';
import 'package:basya_investama/features/home/data/activities_api_client.dart';
import 'package:basya_investama/features/home/domain/investor_home_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final session = AuthSession(
    accessToken: 'test',
    tokenType: 'Bearer',
    expiresAt: DateTime(2030),
  );
  Map<String, dynamic> item(String direction) => {
    'id': 'investment:153',
    'type': 'investment_purchase',
    'title': 'Pembelian investasi',
    'reference_id': 'SE123',
    'direction': direction,
    'amount': 1200000,
    'occurred_at': '2026-10-21 09:53:06',
    'status': {'code': 'success', 'label': 'Berhasil'},
  };
  test(
    'authorized GET maps amounts, direction, reference and status',
    () async {
      final api = ActivitiesApiClient(
        client: MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url, ActivitiesApiClient.activitiesUri);
          expect(request.headers['Authorization'], 'Bearer test');
          return http.Response(
            jsonEncode({
              'status': true,
              'data': {
                'currency': 'IDR',
                'limit': 5,
                'activities': [item('outgoing'), item('incoming')],
              },
            }),
            200,
          );
        }),
      );
      addTearDown(api.close);
      final result = await api.getActivities(session);
      expect(result.first.amount, 1200000);
      expect(result.first.direction, HomeActivityDirection.outgoing);
      expect(result.last.direction, HomeActivityDirection.incoming);
      expect(result.first.date, '21 Okt 2026, 09:53');
      expect(result.first.referenceId, 'SE123');
      expect(result.first.statusLabel, 'Berhasil');
    },
  );
  test('empty response remains empty', () async {
    final api = ActivitiesApiClient(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'status': true,
            'data': {'currency': 'IDR', 'activities': []},
          }),
          200,
        ),
      ),
    );
    addTearDown(api.close);
    expect(await api.getActivities(session), isEmpty);
  });
  test('home sends limit while history omits query parameters', () async {
    final urls = <Uri>[];
    final api = ActivitiesApiClient(
      client: MockClient((request) async {
        urls.add(request.url);
        return http.Response(
          jsonEncode({
            'status': true,
            'data': {'currency': 'IDR', 'activities': []},
          }),
          200,
        );
      }),
    );
    addTearDown(api.close);
    await api.getActivities(session, limit: 5);
    await api.getActivities(session);
    expect(urls.first.queryParameters, {'limit': '5'});
    expect(urls.last, ActivitiesApiClient.activitiesUri);
    expect(urls.last.hasQuery, isFalse);
  });
  test('401 HTML response retains session error', () async {
    final api = ActivitiesApiClient(
      client: MockClient((_) async => http.Response('<html/>', 401)),
    );
    addTearDown(api.close);
    await expectLater(
      api.getActivities(session),
      throwsA(
        isA<AuthException>().having(
          (e) => e.type,
          'type',
          AuthFailureType.invalidCredentials,
        ),
      ),
    );
  });
  test('invalid direction does not silently become incoming', () async {
    final api = ActivitiesApiClient(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'status': true,
            'data': {
              'currency': 'IDR',
              'activities': [item('unknown')],
            },
          }),
          200,
        ),
      ),
    );
    addTearDown(api.close);
    await expectLater(
      api.getActivities(session),
      throwsA(
        isA<AuthException>().having(
          (e) => e.type,
          'type',
          AuthFailureType.invalidResponse,
        ),
      ),
    );
  });
}
