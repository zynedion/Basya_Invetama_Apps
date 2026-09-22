import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LastDestinationStore {
  static const _key = 'last_main_destination';
  final _storage = const FlutterSecureStorage();
  Future<void> _pending = Future.value();

  Future<String?> read(String userId) async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null) return null;
      final value = jsonDecode(raw);
      return value is Map && value['userId'] == userId
          ? value['destination'] as String?
          : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> save(String userId, String destination) => _enqueue(
    () => _storage.write(
      key: _key,
      value: jsonEncode({'userId': userId, 'destination': destination}),
    ),
  );

  Future<void> clear() => _enqueue(() => _storage.delete(key: _key));

  Future<void> _enqueue(Future<void> Function() action) {
    _pending = _pending.then((_) => action()).catchError((Object _) {
      // Remembering a tab must not prevent navigation or logout.
    });
    return _pending;
  }
}
