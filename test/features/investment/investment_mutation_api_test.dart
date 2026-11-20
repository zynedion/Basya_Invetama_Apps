import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:basya_investama/features/auth/domain/auth_session.dart';
import 'package:basya_investama/features/investment/data/investment_mutation_api.dart';

void main() {
  final session = AuthSession(
    accessToken: 'test',
    tokenType: 'Bearer',
    expiresAt: DateTime.utc(2030),
  );
  test('pending reads items and preserves OTP metadata', () async {
    final api = InvestmentMutationApi(
      client: MockClient((r) async {
        expect(r.url.path, '/app/investasi/mutasi-sukarela/pending');
        expect(r.headers['Authorization'], 'Bearer test');
        return http.Response(
          jsonEncode({
            'status': true,
            'data': {
              'items': [
                {
                  'id': 1218,
                  'otp': {
                    'expired': true,
                    'can_resend': true,
                    'remaining_seconds': 0,
                  },
                },
              ],
              'total': 1,
            },
          }),
          200,
        );
      }),
    );
    final result = await api.pending(session);
    expect(result.single['id'], 1218);
    expect(result.single['otp']['can_resend'], true);
    api.dispose();
  });
  test('create, resend, verify use correct body and same numeric ID', () async {
    final requests = <http.Request>[];
    final api = InvestmentMutationApi(
      client: MockClient((r) async {
        requests.add(r);
        return http.Response(jsonEncode({'status': true, 'data': {}}), 200);
      }),
    );
    await api.create(session, 1000000, 'Keperluan pribadi');
    await api.resend(session, 1218);
    await api.verify(session, 1218, '001234');
    expect(jsonDecode(requests[0].body), {
      'amount': 1000000,
      'note': 'Keperluan pribadi',
    });
    expect(
      requests[1].url.path,
      '/app/investasi/mutasi-sukarela/1218/resend-otp',
    );
    expect(requests[1].body, isEmpty);
    expect(jsonDecode(requests[2].body), {'otp': '001234'});
    api.dispose();
  });
  for (final status in [401, 410, 422, 429, 500]) {
    test(
      'mutation error $status preserves metadata and is never replayed',
      () async {
        var calls = 0;
        final api = InvestmentMutationApi(
          client: MockClient((r) async {
            calls++;
            return http.Response(
              jsonEncode({
                'status': false,
                'message': 'Error',
                'data': {
                  'otp': {'remaining_attempts': 0},
                },
              }),
              status,
            );
          }),
        );
        await expectLater(
          api.verify(session, 1218, '123456'),
          throwsA(
            isA<InvestmentMutationFailure>()
                .having((e) => e.status, 'status', status)
                .having(
                  (e) => e.data['otp']['remaining_attempts'],
                  'attempts',
                  0,
                ),
          ),
        );
        expect(calls, 1);
        api.dispose();
      },
    );
  }
}
