import 'dart:math';

import 'api_exception.dart';

/// RFC 4122 v4 UUID from a secure RNG (36 chars, valid for the API's 8-128 `Idempotency-Key`).
String uuidV4([Random? rng]) {
  final r = rng ?? Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
}

/// One `Idempotency-Key` per user action. The same key is reused when the action is retried
/// after a network error, 5xx or `IDEMPOTENCY_IN_PROGRESS` (the server replays the first result).
/// It is discarded after success or a final 4xx so the next attempt is a new action.
class IdempotentAction {
  IdempotentAction({String Function()? newKey}) : _newKey = newKey ?? uuidV4;
  final String Function() _newKey;
  String? _key;

  String get key => _key ??= _newKey();

  Future<T> run<T>(Future<T> Function(String key) f) async {
    try {
      final r = await f(key);
      _key = null;
      return r;
    } on ApiException catch (e) {
      if (!e.retryable) _key = null;
      rethrow;
    }
  }

  void reset() => _key = null;
}
