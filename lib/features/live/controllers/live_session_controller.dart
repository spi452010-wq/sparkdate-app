import 'dart:async';

import 'package:clock/clock.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/ui.dart';
import '../../events/data/event_models.dart';
import '../data/live_models.dart';
import '../data/live_session_repository.dart';
import '../services/video_call_service.dart';

/// One controller drives the live flow; the server decides pairing and timing:
/// Waiting Room -> Match Found -> Introduction/Live call -> Call Ended | Early Disconnect
/// -> Waiting for Response | Mutual Connection -> back to queue.
class LiveSessionController extends GetxController {
  LiveSessionController(this._repo, this.video, {this.introLength = const Duration(seconds: 15)});
  final LiveSessionRepository _repo;
  final VideoCallService video;
  final Duration introLength;

  final event = Rxn<SparkEvent>();
  final lobby = Rxn<LobbyStateUpdate>();
  final match = Rxn<LiveMatch>();
  final remaining = Duration.zero.obs;
  final inIntro = true.obs;
  final lastDecision = Rxn<Decision>();
  final endedByMe = false.obs;
  final completedDates = 0.obs;
  final sittingOut = false.obs;
  final reconnecting = false.obs;
  final decisionDeadline = Rxn<DateTime>();
  final mutualConnectionId = RxnString();

  /// serverTime - localTime; every countdown uses [serverNow].
  Duration serverOffset = Duration.zero;
  DateTime get serverNow => clock.now().add(serverOffset);

  StreamSubscription<LiveUpdate>? _sub;
  Timer? _timer;
  DateTime? _callStart;
  bool _inCall = false;

  String get eventId => event.value?.id ?? 'live';

  Future<void> start(SparkEvent? e) async {
    if (e != null) event.value = e;
    if (_sub != null) return;
    _sub = _repo.join(eventId).listen(_on);
    try {
      serverOffset = await _repo.serverTimeOffset();
    } catch (_) {
      serverOffset = Duration.zero;
    }
  }

  bool _isCurrent(String dateId) => match.value?.dateId == dateId;

  void _on(LiveUpdate u) {
    switch (u) {
      case LobbyStateUpdate():
        lobby.value = u;
      case NoMatchUpdate():
        sittingOut.value = true;
        if (Get.currentRoute != Routes.waitingRoom) Get.offNamed(Routes.waitingRoom);
      case MatchFoundUpdate():
        _onMatch(u.match);
      case RoundStartedUpdate():
        if (_isCurrent(u.dateId)) match.value = match.value!.copyWith(endsAt: u.endsAt);
        _tickCall();
      case RoundEndedUpdate():
        if (!_isCurrent(u.dateId)) return;
        decisionDeadline.value = u.decisionDeadline;
        _roundOver();
      case PartnerLeftUpdate():
        if (!_isCurrent(u.dateId)) return;
        _hangUp();
        endedByMe.value = false;
        Get.offNamed(Routes.earlyDisconnect);
      case ConnectionMutualUpdate():
        mutualConnectionId.value = u.connectionId;
        if (Get.currentRoute == Routes.waitingResponse || Get.currentRoute == Routes.callEnded) Get.offNamed(Routes.mutualConnection);
      case EventEndedUpdate():
        completedDates.value = u.datesCompleted;
        u.datesCompleted == 0 ? leave(to: Routes.refund, arguments: eventId) : leave();
      case ReconnectingUpdate():
        reconnecting.value = true;
      case ReconnectedUpdate():
        reconnecting.value = false;
      case GraceExpiredUpdate():
        reconnecting.value = false;
        if (match.value != null && (_inCall || Get.currentRoute == Routes.matchFound)) {
          _hangUp();
          endedByMe.value = false;
          Get.offNamed(Routes.earlyDisconnect);
        }
      case JoinRejectedUpdate():
        showError(u.error);
    }
  }

  Future<void> _onMatch(LiveMatch m) async {
    sittingOut.value = false;
    final resend = _isCurrent(m.dateId);
    match.value = m;
    if (resend) {
      // Reconnect within grace: server resent match:found with a fresh token for the same room.
      if (_inCall) {
        await video.disconnect();
        try {
          await video.connect(m.livekitUrl, m.livekitToken);
        } catch (e) {
          showError(e);
        }
      }
      return;
    }
    _hangUp();
    decisionDeadline.value = null;
    mutualConnectionId.value = null;
    Get.offNamed(Routes.matchFound);
  }

  Future<void> connectNow() async {
    final m = match.value;
    if (m == null || _inCall) return;
    try {
      await video.connect(m.livekitUrl, m.livekitToken);
    } catch (e) {
      showError(e);
      return;
    }
    _inCall = true;
    _callStart = clock.now();
    inIntro.value = true;
    _timer?.cancel();
    _tickCall();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tickCall());
    Get.offNamed(Routes.liveCall);
  }

  /// Countdown = endsAt (server time) - serverNow. Navigation waits for `round:ended`.
  void _tickCall() {
    final m = match.value;
    if (m == null) return;
    if (_callStart != null && clock.now().difference(_callStart!) >= introLength) inIntro.value = false;
    final d = m.endsAt.difference(serverNow);
    remaining.value = d.isNegative ? Duration.zero : d;
  }

  void _hangUp() {
    _timer?.cancel();
    if (_inCall) video.disconnect();
    _inCall = false;
  }

  void _roundOver() {
    if (Get.currentRoute == Routes.callEnded) return;
    _hangUp();
    Get.offNamed(Routes.callEnded);
  }

  Future<void> sendSpark() async {
    final m = match.value;
    if (m == null) return;
    try {
      await _repo.spark(m.dateId);
      Get.rawSnackbar(message: 'Spark sent ✨');
    } catch (e) {
      showError(e);
    }
  }

  Future<void> endEarly() async {
    _hangUp();
    endedByMe.value = true;
    try {
      await _repo.endDate();
    } catch (_) {}
    Get.offNamed(Routes.earlyDisconnect);
  }

  bool get decisionOpen {
    final d = decisionDeadline.value;
    return d == null || serverNow.isBefore(d);
  }

  Future<void> decide(Decision d) async {
    final m = match.value;
    if (m == null) return;
    if (!decisionOpen) {
      showError('Decision time is over for this date');
      return backToQueue();
    }
    lastDecision.value = d;
    try {
      await _repo.decide(m.dateId, d);
      if (d == Decision.pass) return backToQueue();
      Get.offNamed(mutualConnectionId.value != null ? Routes.mutualConnection : Routes.waitingResponse);
    } catch (e) {
      showError(e);
    }
  }

  /// Back to the waiting room; re-sends `event:join` so the server queues us for the next round.
  Future<void> backToQueue() async {
    _hangUp();
    match.value = null;
    Get.offNamed(Routes.waitingRoom);
    try {
      await _repo.rejoin();
    } catch (_) {}
  }

  Future<void> leave({String to = Routes.home, Object? arguments}) async {
    _hangUp();
    final sub = _sub;
    _sub = null;
    unawaited(sub?.cancel());
    unawaited(_repo.leave().catchError((_) {}));
    Get.offAllNamed(to, arguments: arguments);
    Future.microtask(() => Get.delete<LiveSessionController>(force: true));
  }

  @override
  void onClose() {
    _timer?.cancel();
    _sub?.cancel();
    super.onClose();
  }
}
