import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sparkdate/features/auth/data/auth_providers.dart';
import 'package:sparkdate/features/auth/data/mock_auth_repository.dart';
import 'package:sparkdate/features/auth/presentation/login_screen.dart';
import 'package:sparkdate/features/onboarding/presentation/onboarding_screen.dart';
import 'package:sparkdate/features/profile/presentation/complete_profile_screen.dart';

Widget _wrap(Widget child) => ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(MockAuthRepository(latency: Duration.zero))],
      child: MaterialApp(home: child),
    );

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('onboarding shows first page copy', (t) async {
    await t.pumpWidget(_wrap(const OnboardingScreen()));
    expect(find.textContaining('Discover Meaningful'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('login rejects invalid phone', (t) async {
    await t.pumpWidget(_wrap(const LoginScreen()));
    await t.enterText(find.byKey(const Key('phoneField')), '12345');
    await t.tap(find.byKey(const Key('continueWhatsApp')));
    await t.pump();
    expect(find.text('Enter a valid 10-digit mobile number'), findsOneWidget);
  });

  testWidgets('complete profile shows required errors on empty submit', (t) async {
    t.view.physicalSize = const Size(1080, 4000);
    t.view.devicePixelRatio = 2.5;
    addTearDown(t.view.reset);
    await t.pumpWidget(_wrap(const CompleteProfileScreen()));
    await t.tap(find.byKey(const Key('saveProfile')));
    await t.pump();
    expect(find.byKey(const Key('err_name')), findsOneWidget);
    expect(find.byKey(const Key('err_dob')), findsOneWidget);
    expect(find.byKey(const Key('err_photo')), findsOneWidget);
  });
}
