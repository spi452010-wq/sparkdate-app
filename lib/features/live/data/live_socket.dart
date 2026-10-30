import 'dart:async';

import 'package:clock/clock.dart';
import 'package:dio/dio.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

enum LiveConnection { connected, disconnected }

/// Thin transport over Socket.IO namespace `/live`, so the session state machine can be tested with a fake.
abstract interface class LiveSocket {
  Stream<LiveConnection> get connection;

  /// Server -> client events as (name, payload).
  Stream<(String, Object?)> get events;
  void connect();

  /// Client -> server events are acked with `{ok, error?}`.
  Future<Map<String, dynamic>> emitAck(String event, Map<String, dynamic> payload);
  Future<void> dispose();
}

/// Server time source for countdown offset (`GET /live/time`).
abstract interface class ServerTimeSource {
  Future<DateTime> now();
}

class RemoteServerTime implements ServerTimeSource {
  RemoteServerTime(this._dio);
  final Dio _dio;

  /// Response shape is not fixed by the contract; accepts `{serverTime|now|time: ISO|ms}`.
  @override
  Future<DateTime> now() async {
    final r = await _dio.get<Map<String, dynamic>>('/live/time');
    final v = r.data?['serverTime'] ?? r.data?['now'] ?? r.data?['time'];
    return v is num ? DateTime.fromMillisecondsSinceEpoch(v.toInt(), isUtc: true) : DateTime.parse(v as String);
  }
}

class SocketIoLiveSocket implements LiveSocket {
  SocketIoLiveSocket(this.apiBaseUrl, this.accessToken);
  final String apiBaseUrl;
  final String? Function() accessToken;
  io.Socket? _s;
  final _conn = StreamController<LiveConnection>.broadcast();
  final _events = StreamController<(String, Object?)>.broadcast();

  static const _serverEvents = [
    'lobby:state', 'match:found', 'round:started', 'round:ended', 'partner:left', 'connection:mutual', 'no:match', 'event:ended', //
  ];

  @override
  Stream<LiveConnection> get connection => _conn.stream;
  @override
  Stream<(String, Object?)> get events => _events.stream;

  @override
  void connect() {
    final origin = Uri.parse(apiBaseUrl).origin;
    final s = _s = io.io(
        '$origin/live',
        io.OptionBuilder()
            .setTransports(['websocket'])
            .setAuthFn((cb) => cb({'token': accessToken()}))
            .enableReconnection()
            .disableAutoConnect()
            .build());
    s.onConnect((_) => _conn.add(LiveConnection.connected));
    s.onDisconnect((_) => _conn.add(LiveConnection.disconnected));
    for (final e in _serverEvents) {
      s.on(e, (d) => _events.add((e, d)));
    }
    s.connect();
  }

  @override
  Future<Map<String, dynamic>> emitAck(String event, Map<String, dynamic> payload) {
    final done = Completer<Map<String, dynamic>>();
    _s!.emitWithAck(event, payload, ack: (dynamic r) {
      if (!done.isCompleted) done.complete(r is Map ? Map<String, dynamic>.from(r) : {'ok': false, 'error': 'BAD_ACK'});
    });
    return done.future.timeout(const Duration(seconds: 10));
  }

  @override
  Future<void> dispose() async {
    _s?.dispose();
    _s = null;
  }
}

/// Clock helper: server time = local time + offset.
Duration offsetFrom(DateTime serverNow, DateTime sentAt, DateTime receivedAt) {
  final mid = sentAt.add(receivedAt.difference(sentAt) ~/ 2);
  return serverNow.difference(mid);
}

DateTime localNow() => clock.now();
