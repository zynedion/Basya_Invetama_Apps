import 'dart:convert';
import 'package:basya_investama/core/notifications/fcm_token_api.dart';
import 'package:basya_investama/features/auth/domain/auth_session.dart';
import 'package:basya_investama/features/auth/data/auth_api_client.dart';
import 'package:basya_investama/features/auth/data/auth_service.dart';
import 'package:basya_investama/features/auth/data/secure_session_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test(
    'Startup reuses active token, renews expired token, logout retains username',
    () async {
      var requests = 0;
      final repository = SecureSessionRepository();
      final api = AuthApiClient(
        client: MockClient((request) async {
          requests++;
          expect(jsonDecode(request.body), {
            'username': 'member',
            'password': 'test-password',
          });
          return http.Response(
            jsonEncode({
              'status': true,
              'token': 'token-$requests',
              'token_type': 'Bearer',
              'expires_in': 3600,
            }),
            200,
          );
        }),
      );
      final auth = AuthService(api: api, sessions: repository);
      await auth.login(username: ' member ', password: 'test-password');
      expect(await repository.readUsername(), 'member');
      expect(await repository.readPassword(), 'test-password');
      final restarted = AuthService(
        api: api,
        sessions: SecureSessionRepository(),
        fcm: FcmTokenApi(
          client: MockClient((request) async {
            expect(request.method, 'PUT');
            expect(jsonDecode(request.body), {'fcm_token': ''});
            expect(request.headers['Authorization'], 'Bearer token-2');
            expect(await repository.read(), isNotNull);
            expect(await repository.readPassword(), 'test-password');
            return http.Response('', 204);
          }),
        ),
      );
      expect((await restarted.restoreSession())!.accessToken, 'token-1');
      expect(requests, 1);
      await repository.save(
        AuthSession(
          accessToken: 'expired',
          tokenType: 'Bearer',
          expiresAt: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
        ),
      );
      expect(await restarted.readActiveSession(), isNull);
      expect((await restarted.restoreSession())!.accessToken, 'token-2');
      expect(requests, 2);
      await restarted.logout();
      expect(await repository.readPassword(), isNull);
      expect(await repository.read(), isNull);
      expect(await restarted.readSavedUsername(), 'member');
      expect(await restarted.restoreSession(), isNull);
      expect(requests, 2);
    },
  );

  test('Rejected login does not persist a password', () async {
    final repository = SecureSessionRepository();
    final auth = AuthService(
      sessions: repository,
      api: AuthApiClient(
        client: MockClient((_) async => http.Response('{}', 401)),
      ),
    );
    await expectLater(
      auth.login(username: 'member', password: 'wrong'),
      throwsException,
    );
    expect(await repository.readPassword(), isNull);
    expect(await repository.read(), isNull);
  });

  test('Failed FCM removal preserves session for logout retry', () async {
    final repository = SecureSessionRepository();
    await repository.save(
      AuthSession(
        accessToken: 'session',
        tokenType: 'Bearer',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      ),
    );
    await repository.saveCredentials('member', 'password');
    var attempts = 0;
    final auth = AuthService(
      sessions: repository,
      fcm: FcmTokenApi(
        client: MockClient((_) async {
          attempts++;
          return http.Response('', attempts == 1 ? 500 : 204);
        }),
      ),
    );
    await expectLater(auth.logout(), throwsStateError);
    expect(await repository.read(), isNotNull);
    expect(await repository.readPassword(), 'password');
    await auth.logout();
    expect(await repository.read(), isNull);
    expect(await repository.readPassword(), isNull);
  });
}
