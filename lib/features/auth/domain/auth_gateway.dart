import 'auth_profile.dart';
import 'auth_session.dart';

abstract interface class AuthGateway {
  Future<AuthSession> login({
    required String username,
    required String password,
  });
  Future<AuthProfile> getProfile(AuthSession session);
  Future<AuthSession?> restoreSession();
  Future<AuthSession?> readActiveSession();
  Future<String?> readSavedUsername();
  Future<void> logout();
}
