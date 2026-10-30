import 'dart:async';

import 'package:clock/clock.dart';

import 'package:socket_io_client/socket_io_client.dart' as io;

import 'live_models.dart';

/// Live event signalling (Socket.IO `event:join`, `match:found`, `round:ended`, `partner:left`…).
abstract interface class LiveSessionRepository {
  Stream<LiveUpdate> join(String eventId);
  Future<void> leave();

  /// Submit like/save/pass within 60 s after `round:ended`.
  Future<DecisionResult> decide(String matchId, Decision d);

  /// Ends the current date early (user tapped End).
  Future<void> endEarly(String matchId);
}

class MockLiveSessionRepository implements LiveSessionRepository {
  MockLiveSessionRepository({this.queueDelay = const Duration(seconds: 3), this.roundLength = const Duration(minutes: 3), this.partnerLikesYou = true});
  final Duration queueDelay;
  final Duration roundLength;
  bool partnerLikesYou;
  StreamController<LiveUpdate>? _c;
  Timer? _t;
  int _round = 0;

  @override
  Stream<LiveUpdate> join(String eventId) {
    _c?.close();
    final c = _c = StreamController<LiveUpdate>();
    c.add(QueueUpdate(waiting: 14, attempt: _round % 3 + 1, maxAttempts: 3, eventNo: '284'));
    _t = Timer(queueDelay, () {
      if (c.isClosed) return;
      _round++;
      c.add(MatchFoundUpdate(LiveMatch(
        matchId: 'm_$_round',
        partnerId: 'u_riya',
        name: 'Riya',
        age: 27,
        city: 'Indore',
        round: _round,
        bio: 'Coffee lover, weekend trekker and amateur photographer.',
        interests: const ['Travel', 'Music', 'Photography'],
        roomUrl: 'wss://mock.livekit',
        roomToken: 'mock',
        roundEndsAt: clock.now().add(roundLength + const Duration(seconds: 8)),
      )));
    });
    return c.stream;
  }

  @override
  Future<void> leave() async {
    _t?.cancel();
    await _c?.close();
    _c = null;
  }

  @override
  Future<DecisionResult> decide(String matchId, Decision d) async =>
      DecisionResult(mutual: d != Decision.pass && partnerLikesYou, connectionId: 'c_$matchId');

  @override
  Future<void> endEarly(String matchId) async {}
}

/// Socket.IO client against the API's live module. Payload shapes are provisional.
class SocketLiveSessionRepository implements LiveSessionRepository {
  SocketLiveSessionRepository(this.baseUrl, this.accessToken);
  final String baseUrl;
  final String? Function() accessToken;
  io.Socket? _s;
  StreamController<LiveUpdate>? _c;

  @override
  Stream<LiveUpdate> join(String eventId) {
    final c = _c = StreamController<LiveUpdate>();
    final s = _s = io.io(baseUrl, io.OptionBuilder().setTransports(['websocket']).setAuth({'token': accessToken()}).build());
    s.onConnect((_) => s.emit('event:join', {'eventId': eventId}));
    s.on('queue:update', (d) {
      final m = d as Map;
      c.add(QueueUpdate(waiting: m['waiting'] as int, attempt: m['attempt'] as int, maxAttempts: m['maxAttempts'] as int, eventNo: m['eventNo']?.toString()));
    });
    s.on('match:found', (d) => c.add(MatchFoundUpdate(LiveMatch.fromJson(Map<String, dynamic>.from(d as Map)))));
    s.on('round:ended', (_) => c.add(const RoundEndedUpdate()));
    s.on('partner:left', (_) => c.add(const PartnerLeftUpdate()));
    s.on('event:ended', (d) => c.add(EventEndedUpdate(completedDates: (d as Map)['completedDates'] as int? ?? 0)));
    return c.stream;
  }

  Future<Map<String, dynamic>> _ack(String ev, Map<String, dynamic> body) {
    final done = Completer<Map<String, dynamic>>();
    _s!.emitWithAck(ev, body, ack: (dynamic r) => done.complete(Map<String, dynamic>.from((r as Map?) ?? const {})));
    return done.future.timeout(const Duration(seconds: 10));
  }

  @override
  Future<DecisionResult> decide(String matchId, Decision d) async {
    final r = await _ack('round:decision', {'matchId': matchId, 'decision': d.name});
    return DecisionResult(mutual: r['mutual'] == true, connectionId: r['connectionId'] as String?);
  }

  @override
  Future<void> endEarly(String matchId) async => _s?.emit('round:leave', {'matchId': matchId});

  @override
  Future<void> leave() async {
    _s?.dispose();
    await _c?.close();
  }
}
