import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/auth_session.dart';

class SecureSessionRepository {
  SecureSessionRepository({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'auth_access_token';
  static const _tokenTypeKey = 'auth_token_type';
  static const _expiresAtKey = 'auth_expires_at';
  final FlutterSecureStorage _storage;

  Future<void> save(AuthSession session) async {
    await Future.wait([
      _storage.write(key: _tokenKey, value: session.accessToken),
      _storage.write(key: _tokenTypeKey, value: session.tokenType),
      _storage.write(
        key: _expiresAtKey,
        value: session.expiresAt.toUtc().toIso8601String(),
      ),
    ]);
  }

  Future<AuthSession?> read() async {
    final values = await Future.wait([
      _storage.read(key: _tokenKey),
      _storage.read(key: _tokenTypeKey),
      _storage.read(key: _expiresAtKey),
    ]);
    final token = values[0];
    final tokenType = values[1];
    final expiresAt = DateTime.tryParse(values[2] ?? '');
    if (token == null || tokenType == null || expiresAt == null) {
      await clear();
      return null;
    }
    return AuthSession(
      accessToken: token,
      tokenType: tokenType,
      expiresAt: expiresAt.toUtc(),
    );
  }

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _tokenKey),
      _storage.delete(key: _tokenTypeKey),
      _storage.delete(key: _expiresAtKey),
    ]);
  }
}
