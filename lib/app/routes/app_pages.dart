import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../features/auth/views/login_view.dart';
import '../../features/auth/views/verify_otp_view.dart';
import '../../features/events/views/booking_views.dart';
import '../../features/events/views/event_detail_view.dart';
import '../../features/events/views/events_view.dart';
import '../../features/home/views/home_view.dart';
import '../../features/onboarding/views/onboarding_view.dart';
import '../../features/profile/views/complete_profile_view.dart';
import '../../features/splash/views/splash_view.dart';
import '../bindings/feature_bindings.dart';
import 'app_routes.dart';

Widget _todo(String name) => Scaffold(appBar: AppBar(), body: Center(child: Text(name)));

abstract final class AppPages {
  static final pages = <GetPage<dynamic>>[
    GetPage(name: Routes.splash, page: () => const SplashView(), binding: SplashBinding()),
    GetPage(name: Routes.onboarding, page: () => const OnboardingView(), binding: OnboardingBinding()),
    GetPage(name: Routes.login, page: () => const LoginView(), binding: AuthBinding()),
    GetPage(name: Routes.verify, page: () => const VerifyOtpView(), binding: AuthBinding()),
    GetPage(name: Routes.completeProfile, page: () => const CompleteProfileView(), binding: ProfileBinding()),
    GetPage(name: Routes.home, page: () => const HomeView(), binding: HomeBinding()),
    // Events
    GetPage(name: Routes.events, page: () => const EventsView(), binding: EventsBinding()),
    GetPage(name: Routes.eventDetail, page: () => const EventDetailView(), binding: EventDetailBinding()),
    GetPage(name: Routes.freeBooking, page: () => const FreeBookingView(), binding: FreeBookingBinding()),
    GetPage(name: Routes.selfie, page: () => const SelfieView(), binding: SelfieBinding()),
    GetPage(name: Routes.payment, page: () => const PaymentView(), binding: PaymentBinding()),
    GetPage(name: Routes.bookingSuccess, page: () => const BookingSuccessView()),
    // Built in later chunks
    GetPage(name: Routes.waitingRoom, page: () => _todo('Waiting Room')),
    GetPage(name: Routes.chats, page: () => _todo('Chat')),
    GetPage(name: Routes.notifications, page: () => _todo('Notifications')),
    GetPage(name: Routes.profile, page: () => _todo('Profile')),
  ];
}
