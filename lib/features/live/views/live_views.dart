import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/ui.dart';
import '../../events/data/event_models.dart';
import '../controllers/live_session_controller.dart';
import '../data/live_models.dart';

String mmss(Duration d) => '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

/// Waiting Room ("Queue Active • Event #284", "Finding your best match...").
class WaitingRoomView extends StatefulWidget {
  const WaitingRoomView({super.key});
  @override
  State<WaitingRoomView> createState() => _WaitingRoomViewState();
}

class _WaitingRoomViewState extends State<WaitingRoomView> with SingleTickerProviderStateMixin {
  final c = Get.find<LiveSessionController>();
  late final _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    c.start(Get.arguments is SparkEvent ? Get.arguments as SparkEvent : null);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.splashBackground),
          child: SafeArea(
            child: Obx(() {
              final q = c.lobby.value;
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  Row(children: [
                    IconButton(key: const Key('leave_queue'), icon: const Icon(Icons.close, color: Colors.white), onPressed: c.leave),
                    const Spacer(),
                    Pill('Queue Active • Round ${q?.round ?? 1}', color: Colors.white),
                  ]),
                  const Spacer(),
                  ScaleTransition(
                    scale: Tween(begin: .9, end: 1.05).animate(_pulse),
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(.15)),
                      child: const Icon(Icons.favorite, color: Colors.white, size: 64),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Finding your best match...', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                  if (c.sittingOut.value)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('No match this round — you get priority next round.', key: Key('no_match'), style: TextStyle(color: Colors.white70)),
                    ),
                  if (c.reconnecting.value) const Padding(padding: EdgeInsets.only(top: 8), child: Pill('Reconnecting…', color: Colors.white)),
                  const SizedBox(height: 8),
                  Text('${q?.waiting ?? 0} singles waiting', style: const TextStyle(color: Colors.white70)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(.12), borderRadius: BorderRadius.circular(16)),
                    child: Row(children: [
                      const Expanded(child: Text('NEXT ROUND', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 12))),
                      Text(q?.nextRoundAt == null ? '—' : mmss(q!.nextRoundAt!.difference(c.serverNow).isNegative ? Duration.zero : q.nextRoundAt!.difference(c.serverNow)), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                    ]),
                  ),
                ]),
              );
            }),
          ),
        ),
      );
}

/// Match Found ("MUTUAL MATCH", "Riya, 27", 00:08 auto-connect countdown).
class MatchFoundView extends StatefulWidget {
  const MatchFoundView({super.key});
  @override
  State<MatchFoundView> createState() => _MatchFoundViewState();
}

class _MatchFoundViewState extends State<MatchFoundView> {
  final c = Get.find<LiveSessionController>();
  int _left = 8;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _left--);
      if (_left <= 0) _connect();
    });
  }

  void _connect() {
    _t?.cancel();
    c.connectNow();
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = c.match.value;
    if (m == null) return const Scaffold();
    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(24), children: [
          const SizedBox(height: 24),
          const Center(child: Pill('MUTUAL MATCH', color: AppColors.primary, filled: true, icon: Icons.favorite)),
          const SizedBox(height: 24),
          Center(child: Avatar(m.name, size: 140, url: m.photoUrl)),
          const SizedBox(height: 16),
          Text('${m.name}, ${m.age}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          Text(m.city, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Wrap(alignment: WrapAlignment.center, spacing: 6, children: [for (final i in m.interests) Pill(i)]),
          const SizedBox(height: 24),
          Text('Connecting in ${mmss(Duration(seconds: _left.clamp(0, 99)))}',
              key: const Key('match_countdown'), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.violet)),
          const SizedBox(height: 16),
          GradientButton(key: const Key('connect_now'), label: 'Connect Now', onPressed: _connect),
          TextButton(
            onPressed: () => Get.toNamed(Routes.connectionDetail, arguments: m),
            child: const Text('View Full Profile'),
          ),
        ]),
      ),
    );
  }
}

/// Introduction + Live Event call screen (timer, mic/camera/speaker/spark/end, self-view PiP).
class LiveCallView extends GetView<LiveSessionController> {
  const LiveCallView({super.key});

  @override
  Widget build(BuildContext context) {
    final v = controller.video;
    final m = controller.match.value;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        Positioned.fill(child: v.remoteView()),
        Positioned(right: 16, top: 90, width: 110, height: 150, child: ClipRRect(borderRadius: BorderRadius.circular(16), child: v.localView())),
        SafeArea(
          child: Obx(() => Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  Row(children: [
                    Pill(controller.inIntro.value ? 'INTRODUCTION' : 'LIVE', color: AppColors.primary, filled: true),
                    const SizedBox(width: 8),
                    Expanded(child: Text(m == null ? '' : '${m.name}, ${m.age}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
                    Text(mmss(controller.remaining.value), key: const Key('call_timer'), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  ]),
                  if (controller.reconnecting.value)
                    const Padding(padding: EdgeInsets.only(top: 12), child: Pill('Reconnecting… (20 s)', key: Key('reconnecting'), color: Colors.white)),
                  const Spacer(),
                  if (controller.inIntro.value && m != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(16)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Say hi to ${m.name}! 👋', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        if (m.bio.isNotEmpty) Text(m.bio, style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 4),
                        Text('Ice-breaker: ask about ${m.interests.isEmpty ? 'their weekend' : m.interests.first.toLowerCase()}',
                            style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic)),
                      ]),
                    ),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                    _btn(v.micOn.value ? Icons.mic : Icons.mic_off, v.toggleMic, 'mic'),
                    _btn(v.camOn.value ? Icons.videocam : Icons.videocam_off, v.toggleCamera, 'cam'),
                    _btn(v.speakerOn.value ? Icons.volume_up : Icons.hearing, v.toggleSpeaker, 'speaker'),
                    _btn(Icons.auto_awesome, controller.sendSpark, 'spark', color: AppColors.violet),
                    _btn(Icons.call_end, controller.endEarly, 'end', color: AppColors.crimson),
                  ]),
                ]),
              )),
        ),
      ]),
    );
  }

  Widget _btn(IconData i, VoidCallback onTap, String k, {Color color = Colors.white24}) => InkWell(
        key: Key('call_$k'),
        onTap: onTap,
        child: CircleAvatar(radius: 26, backgroundColor: color, child: Icon(i, color: Colors.white)),
      );
}

/// Early Disconnect (you ended, or partner left).
class EarlyDisconnectView extends GetView<LiveSessionController> {
  const EarlyDisconnectView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              const Spacer(),
              StatusHero(
                icon: Icons.call_end,
                color: AppColors.crimson,
                title: 'Call ended early',
                subtitle: controller.endedByMe.value
                    ? 'You left this date before the timer ended. You can still decide on this match.'
                    : '${controller.match.value?.name ?? 'Your match'} disconnected. Don\'t worry — we\'ll find you someone new.',
              ),
              const Spacer(),
              GradientButton(key: const Key('back_to_queue'), label: 'Back to Waiting Room', onPressed: controller.backToQueue),
              if (controller.endedByMe.value)
                TextButton(onPressed: () => Get.offNamed(Routes.callEnded), child: const Text('Like or save this match')),
              TextButton(onPressed: controller.leave, child: const Text('Leave event')),
            ]),
          ),
        ),
      );
}

/// Call Ended — Like / Save / Pass decision.
class CallEndedView extends GetView<LiveSessionController> {
  const CallEndedView({super.key});

  @override
  Widget build(BuildContext context) {
    final m = controller.match.value;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const Spacer(),
            Avatar(m?.name ?? '?', size: 110, url: m?.photoUrl),
            const SizedBox(height: 16),
            const Text('Call Ended', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('How was your date with ${m?.name ?? 'your match'}?', style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            const Text('Your choice stays private unless it\'s mutual.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const Spacer(),
            GradientButton(key: const Key('decide_like'), label: 'Like', onPressed: () => controller.decide(Decision.like)),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              key: const Key('decide_save'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52), shape: const StadiumBorder()),
              icon: const Icon(Icons.bookmark_border),
              label: const Text('Save Connection'),
              onPressed: () => controller.decide(Decision.save),
            ),
            TextButton(key: const Key('decide_pass'), onPressed: () => controller.decide(Decision.pass), child: const Text('Pass')),
          ]),
        ),
      ),
    );
  }
}

/// Waiting for Response ("Both people must save each other…").
class WaitingResponseView extends GetView<LiveSessionController> {
  const WaitingResponseView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              const Spacer(),
              const StatusHero(
                icon: Icons.hourglass_top_rounded,
                color: AppColors.violet,
                title: 'Waiting for Response',
                subtitle: 'Both people must save each other to connect. We\'ll notify you if it\'s a match.',
              ),
              const Spacer(),
              GradientButton(key: const Key('next_round'), label: 'Next Round', onPressed: controller.backToQueue),
              TextButton(onPressed: controller.leave, child: const Text('Leave event')),
            ]),
          ),
        ),
      );
}

/// Mutual Connection ("It's a Mutual Connection!").
class MutualConnectionView extends GetView<LiveSessionController> {
  const MutualConnectionView({super.key});

  @override
  Widget build(BuildContext context) {
    final name = controller.match.value?.name ?? 'Your match';
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.splashBackground),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              const Spacer(),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Avatar('You', size: 90),
                Transform.translate(offset: const Offset(-16, 0), child: Avatar(name, size: 90, url: controller.match.value?.photoUrl)),
              ]),
              const SizedBox(height: 24),
              const Text("It's a Mutual Connection!", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('$name is now added to your Saved Connections', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
              const Spacer(),
              ElevatedButton(
                key: const Key('mutual_chat'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary, minimumSize: const Size.fromHeight(52), shape: const StadiumBorder()),
                onPressed: () => Get.toNamed(Routes.chatSubscription),
                child: const Text('Start Chatting', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              TextButton(onPressed: controller.backToQueue, child: const Text('Next Round', style: TextStyle(color: Colors.white))),
            ]),
          ),
        ),
      ),
    );
  }
}
