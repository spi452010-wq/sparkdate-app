import 'package:get/get.dart';

import '../../features/connections/controllers/connections_controllers.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/events/controllers/events_controllers.dart';
import '../../features/home/controllers/home_controller.dart';
import '../../features/live/controllers/live_session_controller.dart';
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

class HomeBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(() => HomeController(Get.find(), Get.find()));
}

class EventsBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(() => EventsController(Get.find()));
}

class EventDetailBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(() => EventDetailController(Get.find()));
}

class FreeBookingBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(() => FreeBookingController(Get.find(), Get.find()));
}

class SelfieBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(() => SelfieController(Get.find(), Get.find()));
}

class PaymentBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(() => PaymentController(Get.find(), Get.find(), Get.find(), Get.find()));
}

/// Live flow screens share one permanent controller; it deletes itself on leave().
class LiveBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<LiveSessionController>()) {
      Get.put(LiveSessionController(Get.find(), Get.find()), permanent: true);
    }
  }
}

class ConnectionsBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(ConnectionsController.new);
}

class ConnectionDetailBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(ConnectionDetailController.new);
}

class ChatBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(ChatController.new);
}

class ChatSubscriptionBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(ChatSubscriptionController.new);
}

class NotificationsBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(NotificationsController.new);
}
