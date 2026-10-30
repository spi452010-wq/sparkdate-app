import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sparkdate/core/network/api_client.dart';
import 'package:sparkdate/features/auth/controllers/auth_controller.dart';
import 'package:sparkdate/features/auth/data/mock_auth_repository.dart';
import 'package:sparkdate/features/auth/views/login_view.dart';
import 'package:sparkdate/features/onboarding/controllers/onboarding_controller.dart';
import 'package:sparkdate/features/onboarding/views/onboarding_view.dart';
import 'package:sparkdate/features/profile/controllers/profile_controller.dart';
import 'package:sparkdate/features/profile/data/mock_profile_repository.dart';
import 'package:sparkdate/features/profile/views/complete_profile_view.dart';

Widget _wrap(Widget child) => GetMaterialApp(home: child);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() {
    Get.testMode = true;
    final api = Get.put(ApiClient());
    Get.put(AuthController(MockAuthRepository(latency: Duration.zero), api));
    Get.put(ProfileController(MockProfileRepository(latency: Duration.zero)));
    Get.put(OnboardingController());
  });
  tearDown(Get.reset);

  testWidgets('onboarding shows first page copy', (t) async {
    await t.pumpWidget(_wrap(const OnboardingView()));
    expect(find.textContaining('Discover Meaningful'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('login rejects invalid phone', (t) async {
    await t.pumpWidget(_wrap(const LoginView()));
    await t.enterText(find.byKey(const Key('phoneField')), '12345');
    await t.tap(find.byKey(const Key('continueWhatsApp')));
    await t.pump();
    expect(find.text('Enter a valid 10-digit mobile number'), findsOneWidget);
  });

  testWidgets('complete profile shows required errors on empty submit', (t) async {
    t.view.physicalSize = const Size(1080, 4000);
    t.view.devicePixelRatio = 2.5;
    addTearDown(t.view.reset);
    await t.pumpWidget(_wrap(const CompleteProfileView()));
    await t.tap(find.byKey(const Key('saveProfile')));
    await t.pump();
    expect(find.byKey(const Key('err_name')), findsOneWidget);
    expect(find.byKey(const Key('err_dob')), findsOneWidget);
    expect(find.byKey(const Key('err_photo')), findsOneWidget);
  });

  test('AuthController verify stores token in ApiClient', () async {
    final c = Get.find<AuthController>();
    expect(await c.requestOtp('+919876543210'), isTrue);
    expect(c.state.resendIn, 30);
    expect(await c.verify('123456'), isTrue);
    expect(Get.find<ApiClient>().accessToken.value, isNotNull);
  });
}
