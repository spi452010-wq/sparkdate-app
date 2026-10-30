import 'package:get/get.dart';

import '../../features/auth/views/login_view.dart';
import '../../features/auth/views/verify_otp_view.dart';
import '../../features/connections/views/connections_views.dart';
import '../../features/events/views/booking_views.dart';
import '../../features/events/views/event_detail_view.dart';
import '../../features/events/views/events_view.dart';
import '../../features/home/views/home_view.dart';
import '../../features/live/views/live_views.dart';
import '../../features/onboarding/views/onboarding_view.dart';
import '../../features/profile/views/complete_profile_view.dart';
import '../../features/profile/views/my_profile_views.dart';
import '../../features/refund/views/refund_views.dart';
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
    GetPage(name: Routes.home, page: () => const HomeView(), binding: HomeBinding()),
    // Events
    GetPage(name: Routes.events, page: () => const EventsView(), binding: EventsBinding()),
    GetPage(name: Routes.eventDetail, page: () => const EventDetailView(), binding: EventDetailBinding()),
    GetPage(name: Routes.freeBooking, page: () => const FreeBookingView(), binding: FreeBookingBinding()),
    GetPage(name: Routes.selfie, page: () => const SelfieView(), binding: SelfieBinding()),
    GetPage(name: Routes.payment, page: () => const PaymentView(), binding: PaymentBinding()),
    GetPage(name: Routes.bookingSuccess, page: () => const BookingSuccessView()),
    // Live session
    GetPage(name: Routes.waitingRoom, page: () => const WaitingRoomView(), binding: LiveBinding()),
    GetPage(name: Routes.matchFound, page: () => const MatchFoundView(), binding: LiveBinding()),
    GetPage(name: Routes.liveCall, page: () => const LiveCallView(), binding: LiveBinding()),
    GetPage(name: Routes.earlyDisconnect, page: () => const EarlyDisconnectView(), binding: LiveBinding()),
    GetPage(name: Routes.callEnded, page: () => const CallEndedView(), binding: LiveBinding()),
    GetPage(name: Routes.waitingResponse, page: () => const WaitingResponseView(), binding: LiveBinding()),
    GetPage(name: Routes.mutualConnection, page: () => const MutualConnectionView(), binding: LiveBinding()),
    // Connections & chat
    GetPage(name: Routes.likes, page: () => const LikesView(), binding: ConnectionsBinding()),
    GetPage(name: Routes.saved, page: () => const SavedConnectionsView(), binding: ConnectionsBinding()),
    GetPage(name: Routes.connectionDetail, page: () => const ConnectionDetailView(), binding: ConnectionDetailBinding()),
    GetPage(name: Routes.chats, page: () => const ChatsView(), binding: ConnectionsBinding()),
    GetPage(name: Routes.chat, page: () => const ChatView(), binding: ChatBinding()),
    GetPage(name: Routes.chatSubscription, page: () => const ChatSubscriptionView(), binding: ChatSubscriptionBinding()),
    GetPage(name: Routes.subscriptionSuccess, page: () => const SubscriptionSuccessView()),
    GetPage(name: Routes.notifications, page: () => const NotificationsView(), binding: NotificationsBinding()),
    // Profile & refund
    GetPage(name: Routes.profile, page: () => const ProfilePageView(), binding: MyProfileBinding()),
    GetPage(name: Routes.profileDetails, page: () => const ProfileDetailsView(), binding: MyProfileBinding()),
    GetPage(name: Routes.editProfile, page: () => const EditProfileView(), binding: MyProfileBinding()),
    GetPage(name: Routes.refund, page: () => const RefundView(), binding: RefundBinding()),
    GetPage(name: Routes.refundConfirm, page: () => const RefundConfirmView(), binding: RefundBinding()),
    GetPage(name: Routes.refundDone, page: () => const RefundDoneView(), binding: RefundBinding()),
  ];
}
