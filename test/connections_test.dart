import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sparkdate/app/bindings/feature_bindings.dart';
import 'package:sparkdate/app/routes/app_routes.dart';
import 'package:sparkdate/core/network/api_client.dart';
import 'package:sparkdate/core/network/api_exception.dart';
import 'package:sparkdate/features/billing/data/billing_models.dart';
import 'package:sparkdate/features/billing/data/payments_repository.dart';
import 'package:sparkdate/features/billing/services/billing_service.dart';
import 'package:sparkdate/features/connections/data/connections_models.dart';
import 'package:sparkdate/features/connections/data/connections_repository.dart';
import 'package:sparkdate/features/connections/views/connections_views.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('chat requires a Chat Pass', () async {
    final r = MockConnectionsRepository();
    expect(() => r.send('u_ananya', 'hi'),
        throwsA(isA<ApiException>().having((e) => e.error, 'error', ApiErrorCode.chatPassRequired)));
    r.chatPass = true;
    expect((await r.send('u_ananya', 'hi')).fromMe, isTrue);
  });

  group('screens', () {
    late MockConnectionsRepository repo;
    late MockPaymentsRepository payments;
    setUp(() {
      Get.testMode = true;
      Get.put(ApiClient(), permanent: true).userId.value = 'u1';
      repo = Get.put<ConnectionsRepository>(MockConnectionsRepository(), permanent: true) as MockConnectionsRepository;
      Get.put<BillingService>(MockBillingService(), permanent: true);
      payments = Get.put<PaymentsRepository>(MockPaymentsRepository(), permanent: true) as MockPaymentsRepository;
    });
    tearDown(Get.reset);

    Widget app(String initial, {Object? args}) => GetMaterialApp(initialRoute: initial, getPages: [
          GetPage(name: Routes.likes, page: () => const LikesView(), binding: ConnectionsBinding()),
          GetPage(name: Routes.connectionDetail, page: () => const ConnectionDetailView(), binding: ConnectionDetailBinding()),
          GetPage(name: Routes.chat, page: () => const ChatView(), binding: ChatBinding()),
          GetPage(name: Routes.chatSubscription, page: () => const ChatSubscriptionView(), binding: ChatSubscriptionBinding()),
          GetPage(name: Routes.subscriptionSuccess, page: () => const SubscriptionSuccessView()),
        ]);

    testWidgets('likes tabs filter', (t) async {
      await t.pumpWidget(app(Routes.likes));
      await t.pumpAndSettle();
      expect(find.text('Rohan, 28'), findsOneWidget);
      await t.tap(find.byKey(const Key('tab_mutual')));
      await t.pumpAndSettle();
      expect(find.text('Ananya, 26'), findsOneWidget);
      expect(find.text('Rohan, 28'), findsNothing);
    });

    testWidgets('message without pass -> subscribe -> verify -> chat', (t) async {
      await t.pumpWidget(app(Routes.likes));
      await t.pumpAndSettle();
      Get.toNamed(Routes.connectionDetail, arguments: 'u_ananya');
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('detail_message')));
      await t.pumpAndSettle();
      expect(find.text('Unlock Chat'), findsOneWidget);
      await t.tap(find.byKey(const Key('subscribe')));
      await t.pump(const Duration(milliseconds: 300));
      await t.pumpAndSettle();
      expect(find.text('Subscription Successful'), findsOneWidget);
      expect(payments.verified.single.productId, BillingProducts.chatPassMonthly);
      await t.tap(find.byKey(const Key('start_chatting')));
      await t.pumpAndSettle();
      await t.enterText(find.byKey(const Key('chat_input')), 'Hey!');
      await t.tap(find.byKey(const Key('chat_send')));
      await t.pumpAndSettle();
      expect(find.text('Hey!'), findsOneWidget);
      expect(repo.chatPass, isTrue);
      expect(find.byType(ChatView), findsOneWidget);
      expect(Get.arguments, isA<Connection>());
    });
  });
}
