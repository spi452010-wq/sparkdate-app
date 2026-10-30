import 'dart:async';

import 'package:clock/clock.dart';

import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/ui.dart';
import '../../events/data/event_models.dart';
import '../data/live_models.dart';
import '../data/live_session_repository.dart';
import '../services/video_call_service.dart';

/// One controller drives the whole live flow:
/// Waiting Room -> Match Found -> Introduction/Live call -> Call Ended | Early Disconnect
/// -> Waiting for Response | Mutual Connection -> back to queue.
class LiveSessionController extends GetxController {
  LiveSessionController(this._repo, this.video, {this.introLength = const Duration(seconds: 15)});
  final LiveSessionRepository _repo;
  final VideoCallService video;
  final Duration introLength;

  final event = Rxn<SparkEvent>();
  final queue = Rxn<QueueUpdate>();
  final match = Rxn<LiveMatch>();
  final remaining = Duration.zero.obs;
  final inIntro = true.obs;
  final lastDecision = Rxn<Decision>();
  final endedByMe = false.obs;
  final completedDates = 0.obs;

  StreamSubscription<LiveUpdate>? _sub;
  Timer? _timer;
  DateTime? _callStart;

  String get eventId => event.value?.id ?? 'live';

  void start(SparkEvent? e) {
    if (e != null) event.value = e;
    if (_sub != null) return;
    _sub = _repo.join(eventId).listen(_on);
  }

  void _on(LiveUpdate u) {
    switch (u) {
      case QueueUpdate():
        queue.value = u;
      case MatchFoundUpdate():
        match.value = u.match;
        Get.offNamed(Routes.matchFound);
      case PartnerLeftUpdate():
        _hangUp();
        endedByMe.value = false;
        Get.offNamed(Routes.earlyDisconnect);
      case RoundEndedUpdate():
        _roundOver();
      case EventEndedUpdate():
        completedDates.value = u.completedDates;
        u.completedDates == 0 ? leave(to: Routes.refund, arguments: eventId) : leave();
    }
  }

  Future<void> connectNow() async {
    final m = match.value;
    if (m == null) return;
    try {
      await video.connect(m.roomUrl, m.roomToken);
    } catch (e) {
      showError(e);
      return;
    }
    _callStart = clock.now();
    inIntro.value = true;
    _timer?.cancel();
    _tickCall();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tickCall());
    Get.offNamed(Routes.liveCall);
  }

  void _tickCall() {
    final m = match.value;
    if (m == null) return;
    if (_callStart != null && clock.now().difference(_callStart!) >= introLength) inIntro.value = false;
    final d = m.roundEndsAt.difference(clock.now());
    remaining.value = d.isNegative ? Duration.zero : d;
    if (d.isNegative) _roundOver();
  }

  void _hangUp() {
    _timer?.cancel();
    video.disconnect();
  }

  void _roundOver() {
    if (Get.currentRoute == Routes.callEnded) return;
    _hangUp();
    Get.offNamed(Routes.callEnded);
  }

  Future<void> endEarly() async {
    final m = match.value;
    _hangUp();
    endedByMe.value = true;
    if (m != null) await _repo.endEarly(m.matchId);
    Get.offNamed(Routes.earlyDisconnect);
  }

  Future<void> decide(Decision d) async {
    final m = match.value;
    if (m == null) return;
    lastDecision.value = d;
    try {
      final r = await _repo.decide(m.matchId, d);
      if (d == Decision.pass) return backToQueue();
      Get.offNamed(r.mutual ? Routes.mutualConnection : Routes.waitingResponse);
    } catch (e) {
      showError(e);
    }
  }

  /// Rejoin the waiting room for the next round.
  void backToQueue() {
    match.value = null;
    _sub?.cancel();
    _sub = null;
    Get.offNamed(Routes.waitingRoom);
  }

  Future<void> leave({String to = Routes.home, Object? arguments}) async {
    _hangUp();
    await _sub?.cancel();
    _sub = null;
    await _repo.leave();
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
