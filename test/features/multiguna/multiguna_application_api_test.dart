import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:basya_investama/features/auth/domain/auth_session.dart';
import 'package:basya_investama/features/multiguna/data/multiguna_application_api.dart';

void main() {
  final session = AuthSession(
    accessToken: 'test',
    tokenType: 'Bearer',
    expiresAt: DateTime.utc(2030),
  );
  test(
    'list and detail use member endpoints and preserve nullable billing',
    () async {
      final api = MultigunaApplicationApi(
        client: MockClient((r) async {
          if (r.url.path.endsWith('/316')) {
            return http.Response(
              '{"status":true,"data":{"application":{"id":316,"billing":{"start_date":null}}}}',
              200,
            );
          }
          expect(r.url.queryParameters, {
            'status': 'pending',
            'page': '1',
            'per_page': '20',
          });
          return http.Response(
            '{"status":true,"data":{"applications":[{"id":316}],"pagination":{"has_next":false}}}',
            200,
          );
        }),
      );
      final list = await api.applications(session, status: 'pending', page: 1);
      expect((list['applications'] as List).single['id'], 316);
      final item = await api.detail(session, 316);
      expect(item['billing']['start_date'], isNull);
      await expectLater(
        api.applications(session, limit: 3, page: 1),
        throwsArgumentError,
      );
      api.dispose();
    },
  );
  test(
    'simulation preserves setup ID and returns server calculation',
    () async {
      final api = MultigunaApplicationApi(
        client: MockClient((r) async {
          expect(jsonDecode(r.body), {
            'price': 1000000,
            'down_payment': 200000,
            'margin_setup_id': 24,
          });
          expect(r.url.path, '/app/multiguna/pengajuan/simulasi');
          return http.Response(
            jsonEncode({
              'status': true,
              'data': {
                'calculation': {'plafon': 800000, 'within_limit': true},
              },
            }),
            200,
          );
        }),
      );
      final data = await api.simulate(session, {
        'price': 1000000,
        'down_payment': 200000,
        'margin_setup_id': 24,
      });
      expect(data['calculation']['plafon'], 800000);
      api.dispose();
    },
  );
  test(
    'submit sends multipart false and does not replay empty HTTP 500',
    () async {
      var calls = 0;
      final api = MultigunaApplicationApi(
        client: MockClient((r) async {
          calls++;
          expect(r.headers['content-type'], contains('multipart/form-data'));
          expect(r.body, contains('name="has_guarantee"\r\n\r\nfalse'));
          expect(r.body, isNot(contains('start_date')));
          expect(r.body, isNot(contains('due_date')));
          return http.Response('""', 500);
        }),
      );
      await expectLater(
        api.submit(session, {
          'asset_type': 'Peralatan usaha',
          'price': '1000000',
          'down_payment': '200000',
          'margin_setup_id': '24',
          'has_guarantee': 'false',
        }),
        throwsA(
          isA<MultigunaApplicationFailure>().having(
            (e) => e.status,
            'status',
            500,
          ),
        ),
      );
      expect(calls, 1);
      api.dispose();
    },
  );
  test(
    'submit reads application and nullable billing from confirmed envelope',
    () async {
      final api = MultigunaApplicationApi(
        client: MockClient(
          (r) async => http.Response(
            jsonEncode({
              'status': true,
              'data': {
                'application': {
                  'id': 316,
                  'trx_id': 'L261118112950270',
                  'status': {
                    'code': 'pending',
                    'label': 'Menunggu verifikasi admin',
                  },
                  'billing': {
                    'start_date': null,
                    'due_day': null,
                    'end_date': null,
                  },
                },
                'next_action': 'admin_verification',
              },
            }),
            201,
          ),
        ),
      );
      final application = await api.submit(session, {'asset_type': 'Usaha'});
      expect(application['id'], 316);
      expect(application['trx_id'], 'L261118112950270');
      expect(application['status']['code'], 'pending');
      expect(application['billing']['start_date'], isNull);
      api.dispose();
    },
  );
}
