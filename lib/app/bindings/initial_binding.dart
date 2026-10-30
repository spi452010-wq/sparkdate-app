import 'package:get/get.dart';

import '../../core/network/api_client.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/data/mock_auth_repository.dart';
import '../../features/auth/data/remote_auth_repository.dart';
import '../../features/billing/data/payments_repository.dart';
import '../../features/billing/services/billing_service.dart';
import '../../features/events/data/events_repository.dart';
import '../../features/events/data/mock_events_repository.dart';
import '../../features/events/data/remote_events_repository.dart';
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
  }
}
