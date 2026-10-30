import 'package:get/get.dart';

import '../../features/auth/controllers/auth_controller.dart';
import '../../features/onboarding/controllers/onboarding_controller.dart';
import '../../features/profile/controllers/profile_controller.dart';
import '../../features/splash/controllers/splash_controller.dart';

class OnboardingBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(() => OnboardingController());
}

/// Shared by login and verify so the OTP state survives navigation.
class AuthBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(() => AuthController(Get.find(), Get.find()), fenix: true);
}

class ProfileBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(() => ProfileController(Get.find()));
}

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(SplashController());
  }
}
