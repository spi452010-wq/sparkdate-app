import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/verify_otp_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/profile/presentation/complete_profile_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import 'routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.splash,
    routes: [
      GoRoute(path: Routes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: Routes.onboarding, builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: Routes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: Routes.verify, builder: (_, __) => const VerifyOtpScreen()),
      GoRoute(path: Routes.completeProfile, builder: (_, __) => const CompleteProfileScreen()),
      GoRoute(
        path: Routes.home,
        builder: (_, __) => const Scaffold(
          body: Center(child: Text('Home / Events — coming in Sprint 2')),
        ),
      ),
    ],
  );
});
