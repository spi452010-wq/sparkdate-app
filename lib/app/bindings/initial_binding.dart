import 'package:get/get.dart';

import '../../core/network/api_client.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/data/mock_auth_repository.dart';
import '../../features/auth/data/remote_auth_repository.dart';
import '../../features/billing/data/billing_repository.dart';
import '../../features/billing/data/stub_billing_repository.dart';
import '../../features/profile/data/mock_profile_repository.dart';
import '../../features/profile/data/profile_repository.dart';
import '../../features/profile/data/remote_profile_repository.dart';

/// App-wide services and repositories. Mock vs real is chosen by `--dart-define=USE_MOCK`.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    final api = Get.put(ApiClient(), permanent: true);
    Get.lazyPut<AuthRepository>(
      () => useMockApi ? MockAuthRepository() : RemoteAuthRepository(api.dio),
      fenix: true,
    );
    Get.lazyPut<ProfileRepository>(
      () => useMockApi ? MockProfileRepository() : RemoteProfileRepository(api.dio),
      fenix: true,
    );
    Get.lazyPut<BillingRepository>(() => StubBillingRepository(), fenix: true);
  }
}
