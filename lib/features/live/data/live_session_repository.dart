import 'dart:async';

import 'package:clock/clock.dart';

import 'live_models.dart';
import 'live_socket.dart';

/// Live event session (contract: sparkdate-api docs/SPRINT3_LIVE_SESSION.md).
abstract interface class LiveSessionRepository {
  /// Connects and sends `event:join`. Emits parsed server events plus reconnect/grace updates.
  Stream<LiveUpdate> join(String eventId);

  /// serverTime - localTime, from `GET /live/time`.
  Future<Duration> serverTimeOffset();

  /// `date:decision`; throws [LiveAckException] (e.g. after the 60 s window). Mutual arrives as `connection:mutual`.
  Future<void> decide(String dateId, Decision d);

  /// `date:spark` (server rate limit 1/3 s).
  Future<void> spark(String dateId);

  /// `date:leave {dateId}`: ends only this date early; partner gets `partner:left {reason: ended}`,
  /// we stay in the event and the server queues us for the next round.
  Future<void> endDate(String dateId);

  /// `event:leave` + close socket.
  Future<void> leave();
}

/// Socket state machine: join on every (re)connect, 10 s presence ping, 20 s reconnect grace.
class SocketLiveSessionRepository implements LiveSessionRepository {
  SocketLiveSessionRepository(this._socket, this._time, {this.grace = const Duration(seconds: 20), this.ping = const Duration(seconds: 10)});
  final LiveSocket _socket;
  final ServerTimeSource _time;
  final Duration grace;
  final Duration ping;

  StreamController<LiveUpdate>? _c;
  final _subs = <StreamSubscription<Object?>>[];
  String? _eventId;
  bool _wasConnected = false;
  bool _closing = false;
  Timer? _graceTimer;
  Timer? _ping;

  @override
  Stream<LiveUpdate> join(String eventId) {
    _eventId = eventId;
    _closing = false;
    final c = _c = StreamController<LiveUpdate>();
    _subs.add(_socket.connection.listen(_onConnection));
    _subs.add(_socket.events.listen((e) {
      final u = LiveUpdate.fromSocket(e.$1, e.$2);
      if (u != null && !c.isClosed) c.add(u);
    }));
    _socket.connect();
    return c.stream;
  }

  void _add(LiveUpdate u) {
    final c = _c;
    if (c != null && !c.isClosed) c.add(u);
  }

  Future<void> _onConnection(LiveConnection s) async {
    if (s == LiveConnection.connected) {
      final reconnect = _wasConnected;
      _wasConnected = true;
      if (_graceTimer != null) {
        _graceTimer!.cancel();
        _graceTimer = null;
        _add(const ReconnectedUpdate());
      }
      _ping?.cancel();
      _ping = Timer.periodic(ping, (_) => _socket.emitAck('presence:ping', {}).ignore());
      await _sendJoin(reconnect: reconnect);
    } else {
      _ping?.cancel();
      if (_closing || _graceTimer != null) return;
      _add(ReconnectingUpdate(graceEndsAt: clock.now().add(grace)));
      _graceTimer = Timer(grace, () => _add(const GraceExpiredUpdate()));
    }
  }

  Future<void> _sendJoin({bool reconnect = false}) async {
    try {
      final r = await _socket.emitAck('event:join', {'eventId': _eventId});
      if (r['ok'] != true) _add(JoinRejectedUpdate(r['error']?.toString() ?? 'JOIN_FAILED'));
    } catch (_) {
      _add(const JoinRejectedUpdate('TIMEOUT'));
    }
  }

  Future<void> _ack(String ev, Map<String, dynamic> body) async {
    final r = await _socket.emitAck(ev, body);
    if (r['ok'] != true) throw LiveAckException(r['error']?.toString() ?? 'FAILED');
  }

  @override
  Future<Duration> serverTimeOffset() async {
    final sent = clock.now();
    final server = await _time.now();
    return offsetFrom(server, sent, clock.now());
  }

  @override
  Future<void> decide(String dateId, Decision d) => _ack('date:decision', {'dateId': dateId, 'decision': d.name});

  @override
  Future<void> spark(String dateId) => _ack('date:spark', {'dateId': dateId});

  @override
  Future<void> endDate(String dateId) => _ack('date:leave', {'dateId': dateId});

  @override
  Future<void> leave() async {
    _closing = true;
    _graceTimer?.cancel();
    _graceTimer = null;
    _ping?.cancel();
    try {
      await _socket.emitAck('event:leave', {'eventId': _eventId}).timeout(const Duration(seconds: 2));
    } catch (_) {}
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    await _socket.dispose();
    _wasConnected = false;
    unawaited(_c?.close());
  }
}

/// Offline mock that plays the server's part for USE_MOCK builds and widget tests.
class MockLiveSessionRepository implements LiveSessionRepository {
  MockLiveSessionRepository({
    this.queueDelay = const Duration(seconds: 3),
    this.roundLength = const Duration(minutes: 3),
    this.partnerLikesYou = true,
    this.serverOffset = Duration.zero,
  });
  final Duration queueDelay;
  final Duration roundLength;
  bool partnerLikesYou;
  final Duration serverOffset;
  StreamController<LiveUpdate>? _c;
  final _timers = <Timer>[];
  int _round = 0;
  String _eventId = '';
  LiveMatch? _current;

  DateTime get _serverNow => clock.now().add(serverOffset);

  @override
  Stream<LiveUpdate> join(String eventId) {
    _c?.close();
    _eventId = eventId;
    _c = StreamController<LiveUpdate>();
    _queue();
    return _c!.stream;
  }

  void _emit(LiveUpdate u) {
    if (!(_c?.isClosed ?? true)) _c!.add(u);
  }

  void _queue() {
    _emit(LobbyStateUpdate(eventId: _eventId, round: _round + 1, status: 'live', waiting: 14, nextRoundAt: _serverNow.add(queueDelay)));
    _timers.add(Timer(queueDelay, () {
      _round++;
      final start = _serverNow;
      final m = _current = LiveMatch(
        dateId: 'd_$_round',
        round: _round,
        partner: const LivePartner(
            id: 'u_riya', fullName: 'Riya', age: 27, city: 'Indore', interests: ['Travel', 'Music', 'Photography'], bio: 'Coffee lover, weekend trekker and amateur photographer.'),
        livekitUrl: 'wss://mock.livekit',
        livekitRoom: 'evt_${_eventId}_r${_round}_d_$_round',
        livekitToken: 'mock',
        startsAt: start,
        endsAt: start.add(roundLength + const Duration(seconds: 8)),
      );
      _emit(MatchFoundUpdate(m));
      _timers.add(Timer(m.endsAt.difference(_serverNow), () {
        if (_current?.dateId != m.dateId) return;
        _emit(RoundEndedUpdate(dateId: m.dateId, decisionDeadline: _serverNow.add(const Duration(seconds: 60))));
        // Like the server: everyone still in the event is queued for the next round after the decision window.
        _timers.add(Timer(const Duration(seconds: 60), _queue));
      }));
    }));
  }

  @override
  Future<Duration> serverTimeOffset() async => serverOffset;

  @override
  Future<void> decide(String dateId, Decision d) async {
    if (d != Decision.pass && partnerLikesYou && _current != null) {
      final p = _current!.partner;
      scheduleMicrotask(() => _emit(ConnectionMutualUpdate(connectionId: 'c_$dateId', partner: p)));
    }
  }

  @override
  Future<void> spark(String dateId) async {}

  @override
  Future<void> endDate(String dateId) async {
    final next = _current?.endsAt;
    _current = null;
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    // Server keeps us in the event; we are matched again when the next round starts.
    _timers.add(Timer(next == null ? Duration.zero : next.difference(_serverNow), _queue));
  }

  @override
  Future<void> leave() async {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    await _c?.close();
  }
}
