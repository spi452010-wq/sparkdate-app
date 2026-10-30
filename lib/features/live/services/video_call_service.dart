import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

import '../../../core/theme/app_colors.dart';

/// 1:1 video date. Views only talk to this interface.
abstract class VideoCallService extends GetxService {
  final connected = false.obs;
  final micOn = true.obs;
  final camOn = true.obs;
  final speakerOn = true.obs;

  Future<void> connect(String url, String token);
  Future<void> disconnect();
  Future<void> toggleMic();
  Future<void> toggleCamera();
  Future<void> toggleSpeaker();
  Widget remoteView();
  Widget localView();
}

class MockVideoCallService extends VideoCallService {
  @override
  Future<void> connect(String url, String token) async => connected.value = true;
  @override
  Future<void> disconnect() async => connected.value = false;
  @override
  Future<void> toggleMic() async => micOn.toggle();
  @override
  Future<void> toggleCamera() async => camOn.toggle();
  @override
  Future<void> toggleSpeaker() async => speakerOn.toggle();

  @override
  Widget remoteView() => const DecoratedBox(
        decoration: BoxDecoration(gradient: AppColors.splashBackground),
        child: Center(child: Icon(Icons.person, size: 120, color: Colors.white24)),
      );

  @override
  Widget localView() => Obx(() => ColoredBox(
        color: Colors.black87,
        child: Center(child: Icon(camOn.value ? Icons.face : Icons.videocam_off, color: Colors.white54)),
      ));
}

/// LiveKit Cloud implementation (one room per pair per round, token from `match:found`).
class LiveKitVideoCallService extends VideoCallService {
  lk.Room? _room;
  final _tick = 0.obs; // bumps on room changes so Obx re-renders tracks

  @override
  Future<void> connect(String url, String token) async {
    final room = _room = lk.Room(roomOptions: const lk.RoomOptions(adaptiveStream: true, dynacast: true));
    room.addListener(() => _tick.value++);
    await room.connect(url, token);
    await room.localParticipant?.setMicrophoneEnabled(micOn.value);
    await room.localParticipant?.setCameraEnabled(camOn.value);
    connected.value = true;
  }

  @override
  Future<void> disconnect() async {
    await _room?.disconnect();
    await _room?.dispose();
    _room = null;
    connected.value = false;
  }

  @override
  Future<void> toggleMic() async {
    micOn.toggle();
    await _room?.localParticipant?.setMicrophoneEnabled(micOn.value);
  }

  @override
  Future<void> toggleCamera() async {
    camOn.toggle();
    await _room?.localParticipant?.setCameraEnabled(camOn.value);
  }

  @override
  Future<void> toggleSpeaker() async {
    speakerOn.toggle();
    await lk.Hardware.instance.setSpeakerphoneOn(speakerOn.value);
  }

  Widget _render(lk.VideoTrack? t) => t == null ? const ColoredBox(color: Colors.black) : lk.VideoTrackRenderer(t);

  @override
  Widget remoteView() => Obx(() {
        _tick.value;
        final p = _room?.remoteParticipants.values.firstOrNull;
        final pub = p?.videoTrackPublications.firstOrNull;
        return _render(pub?.track as lk.VideoTrack?);
      });

  @override
  Widget localView() => Obx(() {
        _tick.value;
        final pub = _room?.localParticipant?.videoTrackPublications.firstOrNull;
        return _render(pub?.track as lk.VideoTrack?);
      });
}
