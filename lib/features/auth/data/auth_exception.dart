enum AuthFailureType {
  invalidCredentials,
  validation,
  connection,
  timeout,
  server,
  invalidResponse,
}

class AuthException implements Exception {
  const AuthException(this.type, this.message);

  final AuthFailureType type;
  final String message;

  @override
  String toString() => message;
}
