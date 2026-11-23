import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:basya_investama/features/auth/data/auth_api_client.dart';
import 'package:basya_investama/features/auth/data/auth_service.dart';
import 'package:basya_investama/features/auth/data/secure_session_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  for (final status in [200, 400, 500]) {
    final success = status == 200;
    test(
      'password change HTTP $status preserves correct recovery credential',
      () async {
        var changes = 0;
        final started = Completer<void>(), finish = Completer<void>();
        final passwords = <String>[];
        final auth = AuthService(
          api: AuthApiClient(
            client: MockClient((request) async {
              final body = jsonDecode(request.body) as Map;
              if (request.url.path.endsWith('/login')) {
                passwords.add(body['password'] as String);
                return http.Response(
                  jsonEncode({
                    'status': true,
                    'token': 'token-${passwords.length}',
                    'token_type': 'Bearer',
                    'expires_in': 3600,
                  }),
                  200,
                );
              }
              changes++;
              expect(body, {
                'current_password': 'OldPass1',
                'new_password': 'NewPass2',
                'confirm_password': 'NewPass2',
              });
              expect(request.headers['Authorization'], 'Bearer token-1');
              started.complete();
              await finish.future;
              return http.Response(
                jsonEncode(
                  success
                      ? {'status': true}
                      : {
                          'status': 400,
                          'messages': {
                            'current_password': 'Kata sandi lama tidak sesuai',
                          },
                        },
                ),
                status,
              );
            }),
          ),
        );
        final session = await auth.login(
          username: 'user',
          password: 'OldPass1',
        );
        final change = auth.changePassword('OldPass1', 'NewPass2', 'NewPass2');
        final assertion = success
            ? expectLater(change, completes)
            : expectLater(change, throwsException);
        await started.future;
        final renewal = auth.resolve(rejected: session);
        expect(passwords.length, 1);
        finish.complete();
        await assertion;
        await renewal;
        expect(changes, 1);
        expect(passwords.last, success ? 'NewPass2' : 'OldPass1');
        expect(await SecureSessionRepository().readPassword(), passwords.last);
      },
    );
  }
}
