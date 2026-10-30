import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sparkdate/app/bindings/feature_bindings.dart';
import 'package:sparkdate/app/routes/app_routes.dart';
import 'package:sparkdate/features/live/controllers/live_session_controller.dart';
import 'package:sparkdate/features/live/data/live_models.dart';
import 'package:sparkdate/features/live/data/live_session_repository.dart';
import 'package:sparkdate/features/live/data/live_socket.dart';
import 'package:sparkdate/features/live/services/video_call_service.dart';
import 'package:sparkdate/features/live/views/live_views.dart';

class FakeLiveSocket implements LiveSocket {
  final conn = StreamController<LiveConnection>.broadcast();
  final ev = StreamController<(String, Object?)>.broadcast();
  final sent = <(String, Map<String, dynamic>)>[];
  final acks = <String, Map<String, dynamic>>{};
  bool disposed = false;

  @override
  Stream<LiveConnection> get connection => conn.stream;
  @override
  Stream<(String, Object?)> get events => ev.stream;
  @override
  void connect() => scheduleMicrotask(() => conn.add(LiveConnection.connected));
  @override
  Future<Map<String, dynamic>> emitAck(String event, Map<String, dynamic> payload) async {
    sent.add((event, payload));
    return acks[event] ?? {'ok': true};
  }

  @override
  Future<void> dispose() async => disposed = true;

  void server(String e, Object? d) => ev.add((e, d));
  int count(String e) => sent.where((s) => s.$1 == e).length;
}

class FixedServerTime implements ServerTimeSource {
  FixedServerTime(this.offset);
  final Duration offset;
  @override
  Future<DateTime> now() async => clock.now().add(offset);
}

class CountingVideo extends MockVideoCallService {
  final tokens = <String>[];
  @override
  Future<void> connect(String url, String token) async {
    tokens.add(token);
    await super.connect(url, token);
  }
}

Map<String, dynamic> matchJson(DateTime start, {String dateId = 'd1', String token = 't1', Duration len = const Duration(seconds: 30)}) => {
      'dateId': dateId,
      'round': 1,
      'partner': {'id': 'u2', 'fullName': 'Riya', 'age': 27, 'city': 'Indore', 'photoUrl': null, 'interests': ['Music'], 'bio': 'Loves chai'},
      'livekit': {'url': 'wss://lk', 'room': 'evt_e1_r1_$dateId', 'token': token},
      'startsAt': start.toUtc().toIso8601String(),
      'endsAt': start.add(len).toUtc().toIso8601String(),
    };

Future<void> leave(WidgetTester t, LiveSessionRepository r) async {
  await t.runAsync(r.leave);
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('LiveUpdate.fromSocket (contract payloads)', () {
    test('parses every server event', () {
      final m = LiveUpdate.fromSocket('match:found', matchJson(DateTime.utc(2026, 11, 1, 18)))! as MatchFoundUpdate;
      expect(m.match.dateId, 'd1');
      expect(m.match.livekitRoom, 'evt_e1_r1_d1');
      expect(m.match.name, 'Riya');
      expect(m.match.bio, 'Loves chai');
      expect(LiveMatch.fromJson({...matchJson(DateTime.utc(2026)), 'partner': {'id': 'u2', 'bio': null}}).bio, '');
      expect(m.match.endsAt, DateTime.utc(2026, 11, 1, 18, 0, 30));
      expect(LiveUpdate.fromSocket('lobby:state', {'eventId': 'e1', 'round': 2, 'status': 'live', 'waiting': 9, 'nextRoundAt': '2026-11-01T18:00:00Z'}),
          isA<LobbyStateUpdate>().having((u) => u.waiting, 'waiting', 9));
      expect(LiveUpdate.fromSocket('round:started', {'dateId': 'd1', 'endsAt': '2026-11-01T18:03:00Z'}), isA<RoundStartedUpdate>());
      expect(LiveUpdate.fromSocket('round:ended', {'dateId': 'd1', 'decisionDeadline': '2026-11-01T18:04:00Z'}), isA<RoundEndedUpdate>());
      expect(LiveUpdate.fromSocket('partner:left', {'dateId': 'd1', 'reason': 'disconnect'}),
          isA<PartnerLeftUpdate>().having((u) => u.reason, 'reason', 'disconnect'));
      expect(LiveUpdate.fromSocket('partner:left', {'dateId': 'd1', 'reason': 'ended'}),
          isA<PartnerLeftUpdate>().having((u) => u.reason, 'reason', 'ended'));
      expect(LiveUpdate.fromSocket('connection:mutual', {'connectionId': 'c1', 'partner': {'id': 'u2', 'fullName': 'Riya'}}),
          isA<ConnectionMutualUpdate>());
      expect(LiveUpdate.fromSocket('no:match', {'round': 3}), isA<NoMatchUpdate>());
      expect(LiveUpdate.fromSocket('event:ended', {'eventId': 'e1', 'datesCompleted': 2}),
          isA<EventEndedUpdate>().having((u) => u.datesCompleted, 'n', 2));
      expect(LiveUpdate.fromSocket('unknown', {}), isNull);
      expect(LiveUpdate.fromSocket('date:spark', {'dateId': 'd1'}), isA<SparkReceivedUpdate>());
      // Server card for a missing profile: every field but id may be null.
      final nulls = {'id': 'u9', 'fullName': null, 'age': null, 'city': null, 'photoUrl': null, 'interests': <String>[], 'bio': null};
      expect((LiveUpdate.fromSocket('match:found', {...matchJson(DateTime.utc(2026)), 'partner': nulls})! as MatchFoundUpdate).match.bio, '');
      expect((LiveUpdate.fromSocket('connection:mutual', {'connectionId': 'c1', 'partner': nulls})! as ConnectionMutualUpdate).partner.bio, '');
    });
  });

  group('SocketLiveSessionRepository', () {
    testWidgets('joins on connect, pings, re-joins on reconnect within grace', (t) async {
      final s = FakeLiveSocket();
      final repo = SocketLiveSessionRepository(s, FixedServerTime(Duration.zero));
      final got = <LiveUpdate>[];
      repo.join('e1').listen(got.add);
      await t.pump();
      expect(s.sent.first.$1, 'event:join');
      expect(s.sent.first.$2, {'eventId': 'e1'});
      await t.pump(const Duration(seconds: 10));
      expect(s.count('presence:ping'), 1);
      s.conn.add(LiveConnection.disconnected);
      await t.pump(const Duration(seconds: 5));
      expect(got.last, isA<ReconnectingUpdate>());
      s.conn.add(LiveConnection.connected);
      await t.pump();
      expect(got.last, isA<ReconnectedUpdate>());
      expect(s.count('event:join'), 2);
      await t.pump(const Duration(seconds: 30));
      expect(got.whereType<GraceExpiredUpdate>(), isEmpty);
      await leave(t, repo);
      expect(s.disposed, isTrue);
    });

    testWidgets('grace expires after 20 s without reconnect', (t) async {
      final s = FakeLiveSocket();
      final repo = SocketLiveSessionRepository(s, FixedServerTime(Duration.zero));
      final got = <LiveUpdate>[];
      repo.join('e1').listen(got.add);
      await t.pump();
      s.conn.add(LiveConnection.disconnected);
      await t.pump(const Duration(seconds: 19));
      expect(got.whereType<GraceExpiredUpdate>(), isEmpty);
      await t.pump(const Duration(seconds: 2));
      expect(got.whereType<GraceExpiredUpdate>(), hasLength(1));
      await leave(t, repo);
    });

    testWidgets('event:join ack lobby state is applied on join and rejoin; later lobby:state still handled', (t) async {
      final s = FakeLiveSocket()
        ..acks['event:join'] = {
          'ok': true,
          'lobby': {'eventId': 'e1', 'round': 2, 'status': 'live', 'waiting': 7, 'nextRoundAt': '2026-10-30T12:00:00.000Z'},
          'serverTime': 0,
        };
      final repo = SocketLiveSessionRepository(s, FixedServerTime(Duration.zero));
      final got = <LiveUpdate>[];
      repo.join('e1').listen(got.add);
      await t.pump();
      final first = got.whereType<LobbyStateUpdate>().single;
      expect((first.round, first.status, first.waiting), (2, 'live', 7));
      s.conn.add(LiveConnection.disconnected);
      await t.pump();
      s.conn.add(LiveConnection.connected);
      await t.pump();
      expect(got.whereType<LobbyStateUpdate>().length, 2);
      s.server('lobby:state', {'eventId': 'e1', 'round': 3, 'status': 'live', 'waiting': 4, 'nextRoundAt': null});
      await t.pump();
      expect(got.whereType<LobbyStateUpdate>().last.waiting, 4);
      await leave(t, repo);
    });

    testWidgets('rejected join and rejected decision surface errors', (t) async {
      final s = FakeLiveSocket()
        ..acks['event:join'] = {'ok': false, 'error': 'NOT_BOOKED'}
        ..acks['date:decision'] = {'ok': false, 'error': 'DECISION_WINDOW_CLOSED'};
      final repo = SocketLiveSessionRepository(s, FixedServerTime(Duration.zero));
      final got = <LiveUpdate>[];
      repo.join('e1').listen(got.add);
      await t.pump();
      expect(got.single, isA<JoinRejectedUpdate>().having((u) => u.error, 'e', 'NOT_BOOKED'));
      await expectLater(repo.decide('d1', Decision.like), throwsA(isA<LiveAckException>()));
      expect(s.sent.last.$1, 'date:decision');
      expect(s.sent.last.$2, {'dateId': 'd1', 'decision': 'like'});
      await leave(t, repo);
    });

    testWidgets('server time offset', (t) async {
      final repo = SocketLiveSessionRepository(FakeLiveSocket(), FixedServerTime(const Duration(minutes: 5)));
      expect((await repo.serverTimeOffset()).inSeconds, 300);
    });
  });

  group('LiveSessionController state machine', () {
    late FakeLiveSocket s;
    late CountingVideo video;
    const offset = Duration(minutes: 5); // server clock 5 min ahead of the phone

    setUp(() {
      Get.testMode = true;
      s = FakeLiveSocket();
      video = CountingVideo();
      Get.put<LiveSessionRepository>(SocketLiveSessionRepository(s, FixedServerTime(offset)), permanent: true);
      Get.put<VideoCallService>(video, permanent: true);
    });
    tearDown(Get.reset);

    Widget app() => GetMaterialApp(defaultTransition: Transition.noTransition, transitionDuration: Duration.zero, initialRoute: Routes.waitingRoom, getPages: [
          GetPage(name: Routes.home, page: () => const Scaffold(body: Text('home'))),
          GetPage(name: Routes.waitingRoom, page: () => const WaitingRoomView(), binding: LiveBinding()),
          GetPage(name: Routes.matchFound, page: () => const MatchFoundView(), binding: LiveBinding()),
          GetPage(name: Routes.liveCall, page: () => const LiveCallView(), binding: LiveBinding()),
          GetPage(name: Routes.earlyDisconnect, page: () => const EarlyDisconnectView(), binding: LiveBinding()),
          GetPage(name: Routes.callEnded, page: () => const CallEndedView(), binding: LiveBinding()),
          GetPage(name: Routes.waitingResponse, page: () => const WaitingResponseView(), binding: LiveBinding()),
          GetPage(name: Routes.mutualConnection, page: () => const MutualConnectionView(), binding: LiveBinding()),
        ]);

    Future<void> settle(WidgetTester t) async {
      await t.pump();
      for (var i = 0; i < 6; i++) {
        await t.pump(const Duration(milliseconds: 200));
      }
    }

    Future<void> done(WidgetTester t) async {
      Get.offAllNamed(Routes.home);
      await settle(t);
      await leave(t, Get.find<LiveSessionRepository>());
      Get.delete<LiveSessionController>(force: true);
      await t.pump(const Duration(seconds: 1));
    }

    Future<LiveSessionController> inCall(WidgetTester t) async {
      t.view.physicalSize = const Size(1080, 4000);
      t.view.devicePixelRatio = 2.5;
      addTearDown(t.view.reset);
      await t.pumpWidget(app());
      await settle(t);
      final c = Get.find<LiveSessionController>();
      expect(c.serverOffset.inSeconds, 300);
      s.server('match:found', matchJson(clock.now().add(offset)));
      await settle(t);
      expect(Get.currentRoute, Routes.matchFound);
      await t.tap(find.byKey(const Key('connect_now')));
      await settle(t);
      expect(Get.currentRoute, Routes.liveCall);
      return c;
    }

    testWidgets('timer is driven by server endsAt minus offset; round:ended -> decision -> mutual', (t) async {
      final c = await inCall(t);
      // Without the offset the phone would show 5:30 left.
      expect(c.remaining.value.inSeconds, inInclusiveRange(25, 30));
      s.server('round:started', {'dateId': 'd1', 'endsAt': clock.now().add(offset).add(const Duration(seconds: 120)).toUtc().toIso8601String()});
      await t.pump(const Duration(seconds: 1));
      expect(c.remaining.value.inSeconds, inInclusiveRange(116, 120));
      // Local timer reaching 0 does not end the date; the server does.
      await t.pump(const Duration(seconds: 125));
      expect(c.remaining.value, Duration.zero);
      expect(Get.currentRoute, Routes.liveCall);
      s.server('round:ended', {'dateId': 'd1', 'decisionDeadline': clock.now().add(offset).add(const Duration(seconds: 60)).toUtc().toIso8601String()});
      await settle(t);
      expect(Get.currentRoute, Routes.callEnded);
      expect(video.connected.value, isFalse);
      await t.tap(find.byKey(const Key('decide_like')));
      await settle(t);
      expect(s.sent.last.$1, 'date:decision');
      expect(s.sent.last.$2, {'dateId': 'd1', 'decision': 'like'});
      expect(Get.currentRoute, Routes.waitingResponse);
      s.server('connection:mutual', {'connectionId': 'c1', 'partner': {'id': 'u2', 'fullName': 'Riya'}});
      await settle(t);
      expect(Get.currentRoute, Routes.mutualConnection);
      expect(c.mutualConnectionId.value, 'c1');
      await done(t);
    });

    testWidgets('decision after the server deadline is not sent', (t) async {
      await inCall(t);
      s.server('round:ended', {'dateId': 'd1', 'decisionDeadline': clock.now().add(offset).add(const Duration(seconds: 60)).toUtc().toIso8601String()});
      await settle(t);
      await t.pump(const Duration(seconds: 61));
      await t.tap(find.byKey(const Key('decide_like')));
      await settle(t);
      expect(s.count('date:decision'), 0);
      expect(Get.currentRoute, Routes.waitingRoom);
      await t.pump(const Duration(seconds: 5));
      await done(t);
    });

    testWidgets('partner:left ends the call; stale dateId is ignored', (t) async {
      await inCall(t);
      s.server('partner:left', {'dateId': 'other', 'reason': 'left'});
      await settle(t);
      expect(Get.currentRoute, Routes.liveCall);
      s.server('partner:left', {'dateId': 'd1', 'reason': 'disconnect'});
      await settle(t);
      expect(Get.currentRoute, Routes.earlyDisconnect);
      expect(find.textContaining('Riya disconnected'), findsOneWidget);
      await t.tap(find.byKey(const Key('back_to_queue')));
      await settle(t);
      expect(Get.currentRoute, Routes.waitingRoom);
      // Still in the event: no event:leave, no re-join; the server queues us for the next round.
      expect(s.count('event:join'), 1);
      expect(s.count('event:leave'), 0);
      await done(t);
    });

    testWidgets('partner ended the date (reason ended) -> early-ended screen -> back to queue', (t) async {
      await inCall(t);
      s.server('partner:left', {'dateId': 'd1', 'reason': 'ended'});
      await settle(t);
      expect(Get.currentRoute, Routes.earlyDisconnect);
      expect(find.textContaining('Riya ended the date'), findsOneWidget);
      expect(video.connected.value, isFalse);
      await t.tap(find.byKey(const Key('back_to_queue')));
      await settle(t);
      expect(Get.currentRoute, Routes.waitingRoom);
      expect(s.count('event:leave'), 0);
      await done(t);
    });

    for (final code in ['DATE_NOT_FOUND', 'DATE_NOT_ACTIVE', 'VALIDATION_ERROR']) {
      testWidgets('date:leave ack $code (stale date) -> back to the waiting room', (t) async {
        s.acks['date:leave'] = {'ok': false, 'error': code};
        await inCall(t);
        await t.tap(find.byKey(const Key('call_end')));
        await settle(t);
        expect(s.count('date:leave'), 1);
        expect(Get.currentRoute, Routes.waitingRoom);
        expect(video.connected.value, isFalse);
        expect(s.count('event:leave'), 0);
        await t.pump(const Duration(seconds: 4));
        await done(t);
      });
    }

    testWidgets('ending a date early sends date:leave {dateId}, not event:leave', (t) async {
      await inCall(t);
      expect(find.text('Loves chai'), findsOneWidget);
      await t.tap(find.byKey(const Key('call_end')));
      await settle(t);
      expect(Get.currentRoute, Routes.earlyDisconnect);
      expect(s.sent.last.$1, 'date:leave');
      expect(s.sent.last.$2, {'dateId': 'd1'});
      expect(s.count('event:leave'), 0);
      await t.tap(find.byKey(const Key('back_to_queue')));
      await settle(t);
      expect(Get.currentRoute, Routes.waitingRoom);
      expect(s.count('event:join'), 1);
      await done(t);
    });

    testWidgets('reconnect within grace keeps the date and uses the fresh LiveKit token', (t) async {
      final c = await inCall(t);
      s.conn.add(LiveConnection.disconnected);
      await settle(t);
      expect(c.reconnecting.value, isTrue);
      expect(find.byKey(const Key('reconnecting')), findsOneWidget);
      await t.pump(const Duration(seconds: 8));
      s.conn.add(LiveConnection.connected);
      await settle(t);
      expect(c.reconnecting.value, isFalse);
      s.server('match:found', matchJson(clock.now().add(offset), token: 't2'));
      await settle(t);
      expect(Get.currentRoute, Routes.liveCall);
      expect(video.tokens, ['t1', 't2']);
      await t.pump(const Duration(seconds: 30));
      expect(Get.currentRoute, Routes.liveCall);
      await done(t);
    });

    testWidgets('grace expiry ends the date as a disconnect', (t) async {
      final c = await inCall(t);
      s.conn.add(LiveConnection.disconnected);
      await t.pump(const Duration(seconds: 21));
      await settle(t);
      expect(c.reconnecting.value, isFalse);
      expect(Get.currentRoute, Routes.earlyDisconnect);
      expect(video.connected.value, isFalse);
      await done(t);
    });

    testWidgets('no:match keeps the user in the waiting room; event:ended with 0 dates -> refund', (t) async {
      await t.pumpWidget(GetMaterialApp(defaultTransition: Transition.noTransition, transitionDuration: Duration.zero, initialRoute: Routes.waitingRoom, getPages: [
        GetPage(name: Routes.home, page: () => const Scaffold(body: Text('home'))),
        GetPage(name: Routes.refund, page: () => const Scaffold(body: Text('refund'))),
        GetPage(name: Routes.waitingRoom, page: () => const WaitingRoomView(), binding: LiveBinding()),
      ]));
      await settle(t);
      s.server('lobby:state', {'eventId': 'e1', 'round': 2, 'status': 'live', 'waiting': 9});
      s.server('no:match', {'round': 2});
      await settle(t);
      expect(find.byKey(const Key('no_match')), findsOneWidget);
      expect(find.text('9 singles waiting'), findsOneWidget);
      s.server('event:ended', {'eventId': 'e1', 'datesCompleted': 0});
      await settle(t);
      expect(find.text('refund'), findsOneWidget);
      expect(s.count('event:leave'), 1);
    });
  });
}
