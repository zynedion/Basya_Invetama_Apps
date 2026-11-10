import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:basya_investama/features/auth/domain/auth_session.dart';
import 'package:basya_investama/features/investment/data/investor_registration_api.dart';

void main() {
  final session = AuthSession(
    accessToken: 'test',
    tokenType: 'Bearer',
    expiresAt: DateTime.utc(2030),
  );
  test('GET preserves eligibility, prefill and option IDs', () async {
    final api = InvestorRegistrationApi(
      client: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/app/investor/registration');
        expect(request.headers['Authorization'], 'Bearer test');
        return http.Response(
          jsonEncode({
            'status': true,
            'data': {
              'eligibility': {'can_apply': true},
              'registration': {'state': 'not_registered'},
              'prefill': {'fullname': 'Anggota'},
              'options': {
                'jobs': [
                  {'id': 6, 'name': 'Karyawan'},
                ],
              },
            },
          }),
          200,
        );
      }),
    );
    final data = await api.load(session);
    expect(data['options']['jobs'][0]['id'], 6);
    expect(data['registration']['state'], 'not_registered');
    api.dispose();
  });
  test('POST sends JSON integer IDs once and returns pending state', () async {
    var calls = 0;
    final api = InvestorRegistrationApi(
      client: MockClient((request) async {
        calls++;
        expect(request.method, 'POST');
        final body = jsonDecode(request.body);
        expect(body['jobs'], 6);
        expect(body['graduate'], 26);
        expect(body.containsKey('nasabah_id'), false);
        return http.Response(
          '{"status":true,"data":{"registration":{"state":"pending"}}}',
          201,
        );
      }),
    );
    final data = await api.submit(session, {'jobs': 6, 'graduate': 26});
    expect(data['registration']['state'], 'pending');
    expect(calls, 1);
    api.dispose();
  });
  test('409 and 401 mutations are never retried', () async {
    for (final status in [409, 401]) {
      var calls = 0;
      final api = InvestorRegistrationApi(
        client: MockClient((_) async {
          calls++;
          return http.Response('{"status":false,"message":"Ditolak"}', status);
        }),
      );
      await expectLater(
        api.submit(session, {}),
        throwsA(
          isA<RegistrationFailure>().having((e) => e.status, 'status', status),
        ),
      );
      expect(calls, 1);
      api.dispose();
    }
  });
}
