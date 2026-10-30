import 'package:http/http.dart' as http;
import '../domain/auth_session.dart';

/// Only GETs are replayed. Mutation callers must define their own replay policy.
Future<http.Response> authorizedGet(
  http.Client client,
  Uri uri,
  AuthSession session, {
  Map<String, String>? headers,
}) async {
  final recovery = session.recovery;
  var current = recovery == null ? session : await recovery.resolve();
  Future<http.Response> send() => client
      .get(
        uri,
        headers: {
          ...?headers,
          'Accept': 'application/json',
          'Authorization': current.authorizationHeader,
        },
      )
      .timeout(const Duration(seconds: 20));
  var response = await send();
  if (response.statusCode == 401 && recovery != null) {
    current = await recovery.resolve(rejected: current);
    response = await send();
    if (response.statusCode == 401) await recovery.invalidate();
  }
  return response;
}
