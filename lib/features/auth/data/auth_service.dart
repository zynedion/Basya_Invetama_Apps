import '../../../core/notifications/fcm_token_api.dart';
import 'package:flutter/foundation.dart';
import '../domain/auth_gateway.dart';
import '../domain/auth_profile.dart';
import '../domain/auth_session.dart';
import 'auth_api_client.dart';
import 'auth_exception.dart';
import 'secure_session_repository.dart';

class AuthService implements AuthGateway {
  AuthService({
    AuthApiClient? api,
    SecureSessionRepository? sessions,
    FcmTokenApi? fcm,
  }) : _api = api ?? AuthApiClient(),
       _fcm = fcm ?? FcmTokenApi.shared,
       _sessions = sessions ?? SecureSessionRepository();

  final AuthApiClient _api;
  final FcmTokenApi _fcm;
  final SecureSessionRepository _sessions;

  @override
  Future<AuthProfile> getProfile(AuthSession session) =>
      _api.getProfile(session);

  @override
  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    final session = await _api.login(
      username: username.trim(),
      password: password,
    );
    await _sessions.save(session);
    await _sessions.saveCredentials(username.trim(), password);
    return session;
  }

  @override
  Future<AuthSession?> readActiveSession() async {
    final session = await _sessions.read();
    return session != null && !session.isExpired ? session : null;
  }

  @override
  Future<AuthSession?> restoreSession() async {
    final activeSession = await readActiveSession();
    if (activeSession != null) return activeSession;
    final username = await _sessions.readUsername();
    final password = await _sessions.readPassword();
    if (username != null && password != null) {
      try {
        return await login(username: username, password: password);
      } on AuthException catch (error) {
        if (error.type == AuthFailureType.invalidCredentials) {
          await _sessions.clearPassword();
          await _sessions.clear();
        }
        rethrow;
      }
    }
    final session = await _sessions.read();
    if (session == null) return null;
    if (session.isExpired) {
      await _sessions.clear();
      return null;
    }
    return session;
  }

  @override
  Future<String?> readSavedUsername() => _sessions.readUsername();

  @override
  Future<void> logout() async {
    if (kDebugMode) debugPrint('[AUTH][logout] Reading saved session');
    final session = await _sessions.read();
    if (kDebugMode) {
      debugPrint('[AUTH][logout] Saved session present: ${session != null}');
    }
    if (session != null) await _fcm.clear(session);
    if (kDebugMode) {
      debugPrint('[AUTH][logout] Clearing saved password and session');
    }
    await _sessions.clearPassword();
    await _sessions.clear();
    if (kDebugMode) debugPrint('[AUTH][logout] Completed; username retained');
  }
}
