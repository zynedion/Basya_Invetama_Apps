import 'package:flutter/foundation.dart';

/// Ephemeral data for one login. Never persisted to disk.
class SessionMemoryCache extends ChangeNotifier {
  final _values = <String, Object>{};
  final _requests = <String, int>{};
  int _generation = 0;

  T? read<T>(String key) => _values[key] as T?;

  (int, int) begin(String key) {
    final request = (_requests[key] ?? 0) + 1;
    _requests[key] = request;
    return (_generation, request);
  }

  bool write<T extends Object>(String key, T value, (int, int) ticket) {
    if (ticket.$1 != _generation || ticket.$2 != _requests[key]) return false;
    _values[key] = value;
    return true;
  }

  void clear() {
    _generation++;
    _values.clear();
    _requests.clear();
    notifyListeners();
  }
}
