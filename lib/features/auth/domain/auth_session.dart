abstract interface class SessionRecovery {
  Future<AuthSession> resolve({AuthSession? rejected});
  Future<void> invalidate();
  Stream<void> get sessionExpired;
}

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.tokenType,
    required this.expiresAt,
    this.recovery,
  });

  final String accessToken;
  final String tokenType;
  final DateTime expiresAt;
  final SessionRecovery? recovery;

  bool get isExpired => !expiresAt.isAfter(DateTime.now().toUtc());

  String get authorizationHeader => '$tokenType $accessToken';
}
