import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../features/auth/views/login_view.dart';
import '../../features/auth/views/verify_otp_view.dart';
import '../../features/onboarding/views/onboarding_view.dart';
import '../../features/profile/views/complete_profile_view.dart';
import '../../features/splash/views/splash_view.dart';
import '../bindings/feature_bindings.dart';
import 'app_routes.dart';

abstract final class AppPages {
  static final pages = <GetPage<dynamic>>[
    GetPage(name: Routes.splash, page: () => const SplashView(), binding: SplashBinding()),
    GetPage(name: Routes.onboarding, page: () => const OnboardingView(), binding: OnboardingBinding()),
    GetPage(name: Routes.login, page: () => const LoginView(), binding: AuthBinding()),
    GetPage(name: Routes.verify, page: () => const VerifyOtpView(), binding: AuthBinding()),
    GetPage(name: Routes.completeProfile, page: () => const CompleteProfileView(), binding: ProfileBinding()),
    GetPage(name: Routes.home, page: () => const Scaffold(body: Center(child: Text('Home')))),
  ];
}
