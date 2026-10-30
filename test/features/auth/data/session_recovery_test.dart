import 'package:basya_investama/features/auth/domain/auth_session.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:basya_investama/features/auth/data/auth_api_client.dart';
import 'package:basya_investama/features/auth/data/auth_service.dart';
import 'package:basya_investama/features/auth/data/authorized_request.dart';
import 'package:basya_investama/features/auth/data/secure_session_repository.dart';
import 'package:basya_investama/core/notifications/fcm_token_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final uri = Uri.parse('https://api.basyainvestama.id/app/activities?limit=5');
  http.Response token(String value) => http.Response(
    jsonEncode({
      'status': true,
      'token': value,
      'token_type': 'Bearer',
      'expires_in': 3600,
    }),
    200,
  );
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test(
    'parallel 401 uses one renewal; old pages use newest token; query preserved',
    () async {
      var logins = 0;
      final auth = AuthService(
        api: AuthApiClient(
          client: MockClient((_) async {
            logins++;
            await Future<void>.delayed(const Duration(milliseconds: 5));
            return token('token-$logins');
          }),
        ),
      );
      final session = await auth.login(username: 'user', password: 'secret');
      final client = MockClient((request) async {
        expect(request.url, uri);
        return http.Response(
          '{}',
          request.headers['Authorization'] == 'Bearer token-1' ? 401 : 200,
        );
      });
      final results = await Future.wait(
        List.generate(4, (_) => authorizedGet(client, uri, session)),
      );
      expect(results.every((r) => r.statusCode == 200), isTrue);
      expect(logins, 2);
      expect((await authorizedGet(client, uri, session)).statusCode, 200);
      expect(logins, 2);
      expect((await SecureSessionRepository().read())!.accessToken, 'token-2');
    },
  );

  test(
    'second 401 stops after one replay and emits one expiry event',
    () async {
      var logins = 0;
      var gets = 0;
      final auth = AuthService(
        api: AuthApiClient(
          client: MockClient((_) async => token('token-${++logins}')),
        ),
      );
      final session = await auth.login(username: 'user', password: 'secret');
      var expired = 0;
      final subscription = auth.sessionExpired.listen((_) => expired++);
      addTearDown(subscription.cancel);
      final client = MockClient((_) async {
        gets++;
        return http.Response('{"status":false,"message":"Invalid token"}', 401);
      });
      expect((await authorizedGet(client, uri, session)).statusCode, 401);
      expect(gets, 2);
      expect(logins, 2);
      expect(expired, 1);
      expect(await SecureSessionRepository().readPassword(), isNull);
      await expectLater(authorizedGet(client, uri, session), throwsException);
      expect(gets, 2);
    },
  );

  test(
    'temporary login server failure retains credentials and can retry',
    () async {
      var logins = 0;
      final auth = AuthService(
        api: AuthApiClient(
          client: MockClient((_) async {
            logins++;
            return logins == 2
                ? http.Response('{}', 503)
                : token('token-$logins');
          }),
        ),
      );
      final session = await auth.login(username: 'user', password: 'secret');
      var expired = 0;
      final subscription = auth.sessionExpired.listen((_) => expired++);
      addTearDown(subscription.cancel);
      final client = MockClient(
        (r) async => http.Response(
          '{}',
          r.headers['Authorization'] == 'Bearer token-1' ? 401 : 200,
        ),
      );
      await expectLater(authorizedGet(client, uri, session), throwsException);
      expect(await SecureSessionRepository().readPassword(), 'secret');
      expect(expired, 0);
      expect((await authorizedGet(client, uri, session)).statusCode, 200);
    },
  );

  test(
    'logout during renewal prevents session resurrection and GET replay',
    () async {
      var logins = 0;
      final started = Completer<void>();
      final release = Completer<http.Response>();
      final auth = AuthService(
        api: AuthApiClient(
          client: MockClient((_) async {
            if (++logins == 1) return token('old');
            started.complete();
            return release.future;
          }),
        ),
        fcm: FcmTokenApi(
          client: MockClient((_) async => http.Response('', 401)),
        ),
      );
      final session = await auth.login(username: 'user', password: 'secret');
      var gets = 0;
      final pending = authorizedGet(
        MockClient((_) async {
          gets++;
          return http.Response('{}', 401);
        }),
        uri,
        session,
      );
      final assertion = expectLater(pending, throwsException);
      await started.future;
      final logout = auth.logout();
      release.complete(token('new'));
      await logout;
      await assertion;
      expect(gets, 1);
      expect(await SecureSessionRepository().read(), isNull);
      expect(await SecureSessionRepository().readPassword(), isNull);
    },
  );

  test('401 from login is not replayed and clears saved credentials', () async {
    var logins = 0;
    final auth = AuthService(
      api: AuthApiClient(
        client: MockClient(
          (_) async => ++logins == 1 ? token('old') : http.Response('{}', 401),
        ),
      ),
    );
    final session = await auth.login(username: 'user', password: 'secret');
    await expectLater(
      authorizedGet(
        MockClient((_) async => http.Response('{}', 401)),
        uri,
        session,
      ),
      throwsException,
    );
    expect(logins, 2);
    expect(await SecureSessionRepository().readPassword(), isNull);
  });
  test(
    'near-expiry stored session renews before sending the first GET',
    () async {
      final repository = SecureSessionRepository();
      await repository.save(
        AuthSession(
          accessToken: 'old',
          tokenType: 'Bearer',
          expiresAt: DateTime.now().toUtc().add(const Duration(seconds: 10)),
        ),
      );
      await repository.saveCredentials('user', 'secret');
      var logins = 0;
      final auth = AuthService(
        sessions: repository,
        api: AuthApiClient(
          client: MockClient((_) async {
            logins++;
            return token('fresh');
          }),
        ),
      );
      final session = (await auth.restoreSession())!;
      var gets = 0;
      await authorizedGet(
        MockClient((request) async {
          gets++;
          expect(request.headers['Authorization'], 'Bearer fresh');
          return http.Response('{}', 200);
        }),
        uri,
        session,
      );
      expect(logins, 1);
      expect(gets, 1);
    },
  );
}
