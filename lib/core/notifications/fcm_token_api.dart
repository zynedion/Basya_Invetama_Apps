import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../features/auth/domain/auth_session.dart';

class FcmTokenApi {
  static final shared = FcmTokenApi();
  FcmTokenApi({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  Future<void> _pending = Future<void>.value();
  final Set<String> _revokedSessions = {};

  Future<void> update(AuthSession session, String token) {
    if (session.isExpired || token.trim().isEmpty) {
      return Future.error(
        StateError('An active session and FCM token are required.'),
      );
    }
    return _enqueue(() async {
      if (_revokedSessions.contains(session.accessToken)) return;
      await _send(session, token);
    });
  }

  Future<void> clear(AuthSession session) async {
    // Block queued/late registration and send null after any in-flight PUT.
    _revokedSessions.add(session.accessToken);
    try {
      await _enqueue(() => _send(session, null));
    } catch (_) {
      _revokedSessions.remove(session.accessToken);
      rethrow;
    }
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    final result = _pending.then((_) => operation());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<void> _send(AuthSession session, String? token) async {
    final response = await _client
        .put(
          Uri.parse('https://api.basyainvestama.id/app/profile/fcm-token'),
          headers: {
            'Authorization': session.authorizationHeader,
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({'fcm_token': token}),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('FCM registration failed (${response.statusCode}).');
    }
    if (response.body.trim().isNotEmpty) {
      final body = jsonDecode(response.body);
      if (body is Map && body['status'] == false) {
        throw StateError('FCM registration was rejected.');
      }
    }
  }
}
