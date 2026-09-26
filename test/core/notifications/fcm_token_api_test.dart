import 'dart:convert';
import 'dart:async';
import 'package:basya_investama/core/notifications/fcm_token_api.dart';
import 'package:basya_investama/features/auth/domain/auth_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final session = AuthSession(
    accessToken: 'test-session',
    tokenType: 'Bearer',
    expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
  );
  test(
    'Sends authenticated PUT with only the FCM field; accepts 204',
    () async {
      final api = FcmTokenApi(
        client: MockClient((request) async {
          expect(request.method, 'PUT');
          expect(
            request.url.toString(),
            'https://api.basyainvestama.id/app/profile/fcm-token',
          );
          expect(request.headers['Authorization'], 'Bearer test-session');
          expect(jsonDecode(request.body), {'fcm_token': 'device-token'});
          return http.Response('', 204);
        }),
      );
      await api.update(session, 'device-token');
    },
  );
  for (final status in [401, 500]) {
    test('Rejects HTTP $status so registration can retry', () async {
      final api = FcmTokenApi(
        client: MockClient((_) async => http.Response('{}', status)),
      );
      await expectLater(api.update(session, 'device-token'), throwsStateError);
    });
  }
  test('Rejects an application-level failure', () async {
    final api = FcmTokenApi(
      client: MockClient((_) async => http.Response('{"status":false}', 200)),
    );
    await expectLater(api.update(session, 'device-token'), throwsStateError);
  });
  test('Does not send empty tokens', () async {
    final api = FcmTokenApi(
      client: MockClient((_) async {
        fail('No request expected');
      }),
    );
    await expectLater(api.update(session, ''), throwsStateError);
  });
  test(
    'Clear sends an empty string after in-flight registration and blocks late updates',
    () async {
      final started = Completer<void>();
      final release = Completer<void>();
      final bodies = <Object?>[];
      final api = FcmTokenApi(
        client: MockClient((request) async {
          expect(request.method, 'PUT');
          expect(request.headers['Authorization'], 'Bearer test-session');
          bodies.add(jsonDecode(request.body));
          if (bodies.length == 1) {
            started.complete();
            await release.future;
          }
          return http.Response('', 204);
        }),
      );
      final registration = api.update(session, 'device-token');
      await started.future;
      final removal = api.clear(session);
      final lateRegistration = api.update(session, 'late-token');
      release.complete();
      await Future.wait([registration, removal, lateRegistration]);
      expect(bodies, [
        {'fcm_token': 'device-token'},
        {'fcm_token': ''},
      ]);
    },
  );
}
