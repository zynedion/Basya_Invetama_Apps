import 'dart:convert';

import 'package:basya_investama/features/auth/data/auth_api_client.dart';
import 'package:basya_investama/features/auth/data/auth_exception.dart';
import 'package:basya_investama/features/auth/domain/auth_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'login sends documented JSON and parses a successful JWT response',
    () async {
      late http.Request captured;
      final now = DateTime.utc(2026, 9, 14, 4);
      final client = MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'status': true,
            'message': 'Login berhasil',
            'token': 'jwt-token',
            'token_type': 'Bearer',
            'expires_in': 3600,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final session = await AuthApiClient(
        client: client,
        now: () => now,
      ).login(username: 'user@example.com', password: 'secret');

      expect(captured.method, 'POST');
      expect(captured.url, AuthApiClient.loginUri);
      expect(captured.headers['Content-Type'], 'application/json');
      expect(jsonDecode(captured.body), {
        'username': 'user@example.com',
        'password': 'secret',
      });
      expect(session.accessToken, 'jwt-token');
      expect(session.authorizationHeader, 'Bearer jwt-token');
      expect(session.expiresAt, now.add(const Duration(seconds: 3600)));
    },
  );

  test('401 uses the documented credential error message', () async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'status': 401,
          'error': 401,
          'messages': {'error': 'Username atau password tidak valid'},
        }),
        401,
      ),
    );

    await expectLater(
      AuthApiClient(
        client: client,
      ).login(username: 'invalid', password: 'invalid'),
      throwsA(
        isA<AuthException>()
            .having(
              (error) => error.type,
              'type',
              AuthFailureType.invalidCredentials,
            )
            .having(
              (error) => error.message,
              'message',
              'Username atau password tidak valid',
            ),
      ),
    );
  });

  test('malformed 200 response is rejected without saving a session', () async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({'status': true, 'message': 'Login berhasil'}),
        200,
      ),
    );

    await expectLater(
      AuthApiClient(client: client).login(username: 'user', password: 'pass'),
      throwsA(
        isA<AuthException>().having(
          (error) => error.type,
          'type',
          AuthFailureType.invalidResponse,
        ),
      ),
    );
  });

  test('profile sends bearer token and maps root account identity', () async {
    late http.Request captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(
        jsonEncode({
          'status': true,
          'message': 'Profile berhasil diambil',
          'user': {
            'id': '178',
            'username': 'fakhri@mahirland.id',
            'full_name': 'Fakhri',
            'email': 'fakhri@mahirland.id',
            'foto_user': 'default.png',
            'group_level': 'root',
            'aktif': 'Y',
          },
        }),
        200,
      );
    });
    final session = AuthSession(
      accessToken: 'jwt-token',
      tokenType: 'Bearer',
      expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
    );

    final profile = await AuthApiClient(client: client).getProfile(session);

    expect(captured.method, 'GET');
    expect(captured.url, AuthApiClient.profileUri);
    expect(captured.headers['Authorization'], 'Bearer jwt-token');
    expect(profile.displayName, 'Fakhri');
    expect(profile.avatarUrl, isNull);
    expect(profile.usesInvestorHome, isTrue);
  });
}
