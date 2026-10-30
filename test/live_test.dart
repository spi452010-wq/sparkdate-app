import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sparkdate/app/bindings/feature_bindings.dart';
import 'package:sparkdate/app/routes/app_routes.dart';
import 'package:sparkdate/features/live/controllers/live_session_controller.dart';
import 'package:sparkdate/features/live/data/live_session_repository.dart';
import 'package:sparkdate/features/live/services/video_call_service.dart';
import 'package:sparkdate/features/live/views/live_views.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  late MockLiveSessionRepository repo;

  setUp(() {
    Get.testMode = true;
    repo = MockLiveSessionRepository(queueDelay: const Duration(milliseconds: 100), roundLength: const Duration(seconds: 30));
    Get.put<LiveSessionRepository>(repo, permanent: true);
    Get.put<VideoCallService>(MockVideoCallService(), permanent: true);
  });
  tearDown(Get.reset);

  Widget app() => GetMaterialApp(initialRoute: Routes.waitingRoom, getPages: [
        GetPage(name: Routes.home, page: () => const Scaffold(body: Text('home'))),
        GetPage(name: Routes.waitingRoom, page: () => const WaitingRoomView(), binding: LiveBinding()),
        GetPage(name: Routes.matchFound, page: () => const MatchFoundView(), binding: LiveBinding()),
        GetPage(name: Routes.liveCall, page: () => const LiveCallView(), binding: LiveBinding()),
        GetPage(name: Routes.earlyDisconnect, page: () => const EarlyDisconnectView(), binding: LiveBinding()),
        GetPage(name: Routes.callEnded, page: () => const CallEndedView(), binding: LiveBinding()),
        GetPage(name: Routes.waitingResponse, page: () => const WaitingResponseView(), binding: LiveBinding()),
        GetPage(name: Routes.mutualConnection, page: () => const MutualConnectionView(), binding: LiveBinding()),
      ]);

  Future<void> toCall(WidgetTester t) async {
    t.view.physicalSize = const Size(1080, 4000);
    t.view.devicePixelRatio = 2.5;
    addTearDown(t.view.reset);
    await t.pumpWidget(app());
    expect(find.text('Finding your best match...'), findsOneWidget);
    await t.pump(const Duration(milliseconds: 150));
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('Riya, 27'), findsOneWidget);
    await t.tap(find.byKey(const Key('connect_now')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('call_timer')), findsOneWidget);
    expect(find.text('INTRODUCTION'), findsOneWidget);
  }

  testWidgets('queue -> match -> call -> end early -> back to queue', (t) async {
    await toCall(t);
    await t.tap(find.byKey(const Key('call_end')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('Call ended early'), findsOneWidget);
    await t.tap(find.byKey(const Key('back_to_queue')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
    expect(find.text('Finding your best match...'), findsOneWidget);
    await repo.leave(); // stop the mock's queued round timers
    await Get.delete<LiveSessionController>(force: true);
    await t.pump(const Duration(seconds: 40));
  });

  testWidgets('round ends -> like -> mutual connection / waiting for response', (t) async {
    await toCall(t);
    await t.pump(const Duration(seconds: 40));
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('Call Ended'), findsOneWidget);
    await t.tap(find.byKey(const Key('decide_like')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text("It's a Mutual Connection!"), findsOneWidget);
    expect(find.text('Riya is now added to your Saved Connections'), findsOneWidget);
  });

  testWidgets('one-sided save shows waiting for response', (t) async {
    repo.partnerLikesYou = false;
    await toCall(t);
    await t.pump(const Duration(seconds: 40));
    await t.pump(const Duration(milliseconds: 500));
    await t.tap(find.byKey(const Key('decide_save')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('Waiting for Response'), findsOneWidget);
  });
}
