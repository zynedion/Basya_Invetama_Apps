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
      if (kDebugMode) {
        debugPrint('[FCM][logout] Removal succeeded');
      }
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
    final isLogout = token.isEmpty;
    if (!isLogout && session.recovery != null) {
      session = await session.recovery!.resolve();
    }
    final action = isLogout ? '[FCM][logout]' : '[FCM][update]';
    if (kDebugMode) {
      debugPrint(
        '$action Sending PUT https://api.basyainvestama.id/app/profile/fcm-token',
      );
    }
    if (kDebugMode) {
      debugPrint(
        '$action Headers: Content-Type=application/json; Accept=application/json; Authorization=[REDACTED]',
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
    if (kDebugMode) {
      debugPrint(
        '$action HTTP ${response.statusCode}; content-type=${response.headers['content-type'] ?? '(missing)'}',
      );
    }
    if (isLogout && response.statusCode == 401) return;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (kDebugMode) {
        debugPrint('$action Failed with status code: ${response.statusCode}');
      }
      throw StateError('FCM registration failed (${response.statusCode}).');
    }
    if (response.body.trim().isNotEmpty) {
      final body = jsonDecode(response.body);
      if (body is Map && body['status'] == false) {
        if (kDebugMode) {
          debugPrint('$action Backend rejected FCM registration');
        }
        throw StateError('FCM registration was rejected.');
      }
    }
    if (!isLogout) {
      if (kDebugMode) {
        debugPrint('$action FCM token successfully registered to backend!');
      }
    }
  }
}
