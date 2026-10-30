import 'package:get/get.dart';

import '../../core/network/api_client.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/data/mock_auth_repository.dart';
import '../../features/auth/data/remote_auth_repository.dart';
import '../../features/billing/data/payments_repository.dart';
import '../../features/billing/services/billing_service.dart';
import '../../features/connections/data/connections_repository.dart';
import '../../features/events/data/events_repository.dart';
import '../../features/events/data/mock_events_repository.dart';
import '../../features/events/data/remote_events_repository.dart';
import '../../features/live/data/live_session_repository.dart';
import '../../features/refund/data/refund_repository.dart';
import '../../features/live/services/video_call_service.dart';
import '../../features/profile/data/mock_profile_repository.dart';
import '../../features/profile/data/profile_repository.dart';
import '../../features/profile/data/remote_profile_repository.dart';

/// Repositories are permanent so mock state (bookings, likes…) survives route disposal.
/// App-wide services and repositories. Mock vs real is chosen by `--dart-define=USE_MOCK`.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    final api = Get.put(ApiClient(), permanent: true);
    Get.put<BillingService>(useMockApi ? MockBillingService() : PlayBillingService(), permanent: true);
    Get.put<AuthRepository>(useMockApi ? MockAuthRepository() : RemoteAuthRepository(api.dio), permanent: true);
    Get.put<ProfileRepository>(useMockApi ? MockProfileRepository() : RemoteProfileRepository(api.dio), permanent: true);
    Get.put<EventsRepository>(useMockApi ? MockEventsRepository() : RemoteEventsRepository(api.dio), permanent: true);
    Get.put<PaymentsRepository>(useMockApi ? MockPaymentsRepository() : RemotePaymentsRepository(api.dio), permanent: true);
    Get.put<ConnectionsRepository>(
        useMockApi ? MockConnectionsRepository() : RemoteConnectionsRepository(api.dio, () => api.userId.value ?? ''),
        permanent: true);
    Get.put<RefundRepository>(useMockApi ? MockRefundRepository() : RemoteRefundRepository(api.dio), permanent: true);
    Get.put<VideoCallService>(useMockApi ? MockVideoCallService() : LiveKitVideoCallService(), permanent: true);
    Get.put<LiveSessionRepository>(
        useMockApi ? MockLiveSessionRepository() : SocketLiveSessionRepository(apiBaseUrl, () => api.accessToken.value),
        permanent: true);
  }
}
