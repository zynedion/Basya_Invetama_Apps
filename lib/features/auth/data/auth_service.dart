import 'dart:async';
import '../../../core/notifications/fcm_token_api.dart';
import '../domain/auth_gateway.dart';
import '../domain/auth_profile.dart';
import '../domain/auth_session.dart';
import 'auth_api_client.dart';
import 'auth_exception.dart';
import 'secure_session_repository.dart';

class AuthService implements AuthGateway, SessionRecovery {
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

  final _expired = StreamController<void>.broadcast(sync: true);
  @override
  Stream<void> get sessionExpired => _expired.stream;
  AuthSession? _current;
  Future<AuthSession>? _renewing;
  bool _blocked = false;
  int _generation = 0;

  AuthSession _bind(AuthSession session) => AuthSession(
    accessToken: session.accessToken,
    tokenType: session.tokenType,
    expiresAt: session.expiresAt,
    recovery: this,
  );

  static const _ended = AuthException(
    AuthFailureType.invalidCredentials,
    'Sesi Anda berakhir. Silakan masuk kembali.',
  );

  @override
  Future<AuthSession> resolve({AuthSession? rejected}) async {
    if (_blocked) throw _ended;
    final pending = _renewing;
    if (pending != null) return pending;
    final current = _current;
    if (current != null &&
        current.expiresAt.isAfter(
          DateTime.now().toUtc().add(const Duration(seconds: 30)),
        ) &&
        (rejected == null || rejected.accessToken != current.accessToken)) {
      return current;
    }
    final operation = _renew(_generation);
    _renewing = operation;
    try {
      return await operation;
    } finally {
      if (identical(_renewing, operation)) _renewing = null;
    }
  }

  Future<AuthSession> _renew(int generation) async {
    try {
      final username = await _sessions.readUsername();
      final password = await _sessions.readPassword();
      if (_blocked || generation != _generation) throw _ended;
      if (username == null || password == null) throw _ended;
      final session = await _api.login(username: username, password: password);
      if (_blocked || generation != _generation) throw _ended;
      await _sessions.save(session);
      if (_blocked || generation != _generation) {
        await _sessions.clear();
        throw _ended;
      }
      return _current = _bind(session);
    } on AuthException catch (error) {
      if (error.type == AuthFailureType.invalidCredentials &&
          !_blocked &&
          generation == _generation) {
        await invalidate();
      }
      rethrow;
    }
  }

  @override
  Future<void> invalidate() async {
    if (_blocked) return;
    _blocked = true;
    _generation++;
    _current = null;
    try {
      await _sessions.clearPassword();
      await _sessions.clear();
    } finally {
      _expired.add(null);
    }
  }

  @override
  Future<AuthProfile> getProfile(AuthSession session) =>
      _api.getProfile(session);

  @override
  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    _blocked = false;
    final generation = ++_generation;
    final session = await _api.login(
      username: username.trim(),
      password: password,
    );
    if (_blocked || generation != _generation) throw _ended;
    await _sessions.save(session);
    await _sessions.saveCredentials(username.trim(), password);
    return _current = _bind(session);
  }

  @override
  Future<AuthSession?> readActiveSession() async {
    final session = await _sessions.read();
    return session != null && !session.isExpired
        ? (_current = _bind(session))
        : (_current = null);
  }

  @override
  Future<AuthSession?> restoreSession() async {
    if (_blocked) return null;
    final active = await readActiveSession();
    if (active != null) return active;
    if (await _sessions.readUsername() == null ||
        await _sessions.readPassword() == null) {
      await _sessions.clear();
      return null;
    }
    return resolve();
  }

  @override
  Future<String?> readSavedUsername() => _sessions.readUsername();

  @override
  Future<void> logout() async {
    _blocked = true;
    _generation++;
    final pending = _renewing;
    if (pending != null) {
      try {
        await pending;
      } catch (_) {
        /* Logout owns cleanup. */
      }
    }
    final session = await _sessions.read();
    try {
      if (session != null) await _fcm.clear(session);
    } catch (_) {
      _blocked = false;
      rethrow;
    }
    await _sessions.clearPassword();
    await _sessions.clear();
    _current = null;
  }
}
