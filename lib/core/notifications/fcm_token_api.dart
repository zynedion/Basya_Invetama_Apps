import 'dart:convert';
import 'package:flutter/foundation.dart';
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
    if (kDebugMode) {
      debugPrint(
        '[FCM][logout] Queued removal; sessionExpired=${session.isExpired}; '
        'expiresAt=${session.expiresAt.toUtc().toIso8601String()}',
      );
    }
    // Block queued/late registration and send an empty string after any in-flight PUT.
    _revokedSessions.add(session.accessToken);
    try {
      await _enqueue(() => _send(session, ''));
      if (kDebugMode) debugPrint('[FCM][logout] Removal succeeded');
    } catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[FCM][logout] Removal failed: ${error.runtimeType}; '
          'local session retained for retry',
        );
      }
      _revokedSessions.remove(session.accessToken);
      rethrow;
    }
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    final result = _pending.then((_) => operation());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<void> _send(AuthSession session, String token) async {
    if (kDebugMode && token.isEmpty) {
      debugPrint(
        '[FCM][logout] Sending PUT https://api.basyainvestama.id/app/profile/fcm-token',
      );
      debugPrint(
        '[FCM][logout] Headers: Content-Type=application/json; '
        'Accept=application/json; Authorization=[REDACTED]',
      );
      debugPrint(
        '[FCM][logout] Request body: ${jsonEncode({'fcm_token': token})}',
      );
    }
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
    if (kDebugMode && token.isEmpty) {
      debugPrint(
        '[FCM][logout] HTTP ${response.statusCode}; '
        'content-type=${response.headers['content-type'] ?? '(missing)'}',
      );
      debugPrint(
        '[FCM][logout] Response: ${_safeResponse(response.body, session)}',
      );
    }
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

  String _safeResponse(String raw, AuthSession session) {
    if (raw.trim().isEmpty) return '(empty body)';
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return '(JSON without an object; ${raw.length} characters)';
      }
      // Only diagnostics are useful here; never dump a returned user/session object.
      Object? sanitize(Object? value) {
        if (value is Map) {
          return value.map(
            (key, item) => MapEntry(
              key.toString(),
              RegExp(
                    r'token|password|authorization|secret|cookie',
                    caseSensitive: false,
                  ).hasMatch(key.toString())
                  ? '[REDACTED]'
                  : sanitize(item),
            ),
          );
        }
        if (value is List) return value.map(sanitize).toList();
        if (value is String && session.accessToken.isNotEmpty) {
          return value.replaceAll(session.accessToken, '[REDACTED]');
        }
        return value;
      }

      final diagnostic = <String, Object?>{
        for (final key in [
          'status',
          'code',
          'message',
          'messages',
          'error',
          'errors',
        ])
          if (decoded.containsKey(key)) key: sanitize(decoded[key]),
      };
      final text = jsonEncode(diagnostic);
      return text.length > 2000
          ? '${text.substring(0, 2000)}… [truncated]'
          : text;
    } on FormatException {
      return '(non-JSON body; ${raw.length} characters; not printed)';
    }
  }
}
