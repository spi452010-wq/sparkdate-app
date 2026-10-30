import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sparkdate/app/bindings/feature_bindings.dart';
import 'package:sparkdate/app/routes/app_routes.dart';
import 'package:sparkdate/core/network/api_client.dart';
import 'package:sparkdate/features/profile/data/mock_profile_repository.dart';
import 'package:sparkdate/features/profile/data/profile_repository.dart';
import 'package:sparkdate/features/profile/views/my_profile_views.dart';
import 'package:sparkdate/features/refund/data/refund_repository.dart';
import 'package:sparkdate/features/refund/views/refund_views.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  late MockRefundRepository refunds;
  late MockProfileRepository profiles;
  setUp(() {
    Get.testMode = true;
    Get.put(ApiClient(), permanent: true);
    profiles =
        Get.put<ProfileRepository>(MockProfileRepository(latency: Duration.zero), permanent: true) as MockProfileRepository;
    refunds = Get.put<RefundRepository>(MockRefundRepository(), permanent: true) as MockRefundRepository;
  });
  tearDown(Get.reset);

  Widget app(String initial, {Object? args}) => GetMaterialApp(
        initialRoute: initial,
        getPages: [
          GetPage(name: Routes.home, page: () => const Scaffold(body: Text('home'))),
          GetPage(name: '/start', page: () => const Scaffold(body: Text('start'))),
          GetPage(name: Routes.profile, page: () => const ProfilePageView(), binding: MyProfileBinding()),
          GetPage(name: Routes.editProfile, page: () => const EditProfileView(), binding: MyProfileBinding()),
          GetPage(name: Routes.refund, page: () => const RefundView(), binding: RefundBinding()),
          GetPage(name: Routes.refundConfirm, page: () => const RefundConfirmView(), binding: RefundBinding()),
          GetPage(name: Routes.refundDone, page: () => const RefundDoneView(), binding: RefundBinding()),
        ],
      );

  testWidgets('edit profile patches only changed fields', (t) async {
    await t.pumpWidget(app(Routes.profile));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('open_edit')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('edit_name')), 'Priya');
    await t.tap(find.byKey(const Key('edit_save')));
    await t.pumpAndSettle();
    expect(find.text('Priya'), findsOneWidget);
    expect((await profiles.getMe()).fullName, 'Priya');
  });

  testWidgets('refund 01 -> 02 -> 03', (t) async {
    await t.pumpWidget(app('/start'));
    Get.offAllNamed(Routes.refund, arguments: 'evt_1');
    await t.pumpAndSettle();
    expect(find.text('₹199'), findsOneWidget);
    await t.tap(find.byKey(const Key('refund_start')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('reason_technicalIssue')));
    await t.tap(find.byKey(const Key('refund_confirm')));
    await t.pumpAndSettle();
    expect(find.text('Refund Requested'), findsOneWidget);
    expect(refunds.requested, ['bk_evt_1']);
    await t.tap(find.byKey(const Key('refund_home')));
    await t.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
  });
}
