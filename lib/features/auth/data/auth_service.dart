import '../domain/auth_gateway.dart';
import '../domain/auth_profile.dart';
import '../domain/auth_session.dart';
import 'auth_api_client.dart';
import 'secure_session_repository.dart';

class AuthService implements AuthGateway {
  AuthService({AuthApiClient? api, SecureSessionRepository? sessions})
    : _api = api ?? AuthApiClient(),
      _sessions = sessions ?? SecureSessionRepository();

  final AuthApiClient _api;
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
    return session;
  }

  @override
  Future<AuthSession?> restoreSession() async {
    final session = await _sessions.read();
    if (session == null) return null;
    if (session.isExpired) {
      await _sessions.clear();
      return null;
    }
    return session;
  }

  @override
  Future<void> logout() => _sessions.clear();
}
