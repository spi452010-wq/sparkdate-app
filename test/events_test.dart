import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sparkdate/app/bindings/feature_bindings.dart';
import 'package:sparkdate/app/routes/app_routes.dart';
import 'package:sparkdate/core/network/api_client.dart';
import 'package:sparkdate/core/network/api_exception.dart';
import 'package:sparkdate/features/billing/data/payments_repository.dart';
import 'package:sparkdate/features/billing/services/billing_service.dart';
import 'package:sparkdate/features/events/data/event_models.dart';
import 'package:sparkdate/features/events/data/events_repository.dart';
import 'package:sparkdate/features/events/data/mock_events_repository.dart';
import 'package:sparkdate/features/events/views/booking_views.dart';
import 'package:sparkdate/features/events/views/events_view.dart';
import 'package:sparkdate/features/profile/data/mock_profile_repository.dart';
import 'package:sparkdate/features/profile/data/profile_repository.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('MockEventsRepository', () {
    late MockEventsRepository repo;
    setUp(() => repo = MockEventsRepository(latency: Duration.zero));

    test('filters by city and status', () async {
      final r = await repo.list(filter: const EventFilter(cities: {'Bhopal'}, status: EventStatus.live));
      expect(r.map((e) => e.city).toSet(), {'Bhopal'});
    });

    test('paid booking is pending with a 10 min hold; free is confirmed; double booking fails', () async {
      final paid = await repo.book('evt_2');
      expect(paid.status, BookingStatus.pending);
      expect(paid.holdExpiresAt, isNotNull);
      final free = await repo.book('evt_4');
      expect(free.status, BookingStatus.confirmed);
      expect(() => repo.book('evt_4'), throwsA(isA<ApiException>()));
    });

    test('save toggles', () async {
      expect((await repo.setSaved('evt_5', true)).saved, isTrue);
      expect((await repo.get('evt_5')).saved, isTrue);
    });
  });

  group('event screens', () {
    late MockPaymentsRepository payments;
    setUp(() {
      Get.testMode = true;
      Get.put(ApiClient()).userId.value = 'u1';
      Get.put<EventsRepository>(MockEventsRepository(latency: Duration.zero));
      Get.put<ProfileRepository>(MockProfileRepository(latency: Duration.zero));
      Get.put<BillingService>(MockBillingService());
      payments = Get.put<PaymentsRepository>(MockPaymentsRepository()) as MockPaymentsRepository;
    });
    tearDown(Get.reset);

    Widget app(String initial) => GetMaterialApp(initialRoute: initial, getPages: [
          GetPage(name: Routes.events, page: () => const EventsView(), binding: EventsBinding()),
          GetPage(name: Routes.payment, page: () => const PaymentView(), binding: PaymentBinding()),
          GetPage(name: Routes.bookingSuccess, page: () => const BookingSuccessView()),
          GetPage(name: '/start', page: () => const Scaffold(body: Text('start'))),
        ]);

    testWidgets('city filter sheet narrows the list', (t) async {
      t.view.physicalSize = const Size(1080, 4000);
      t.view.devicePixelRatio = 2.5;
      addTearDown(t.view.reset);
      await t.pumpWidget(app(Routes.events));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('event_evt_3')), findsOneWidget);
      await t.tap(find.byKey(const Key('open_filter')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('city_Bhopal')));
      await t.tap(find.byKey(const Key('apply_filter')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('event_evt_2')), findsOneWidget);
      expect(find.byKey(const Key('event_evt_3')), findsNothing);
    });

    testWidgets('paid booking: hold -> Play purchase -> verify -> success', (t) async {
      t.view.physicalSize = const Size(1080, 4000);
      t.view.devicePixelRatio = 2.5;
      addTearDown(t.view.reset);
      await t.pumpWidget(app('/start'));
      final e = await Get.find<EventsRepository>().get('evt_2');
      Get.toNamed(Routes.payment, arguments: e);
      await t.pumpAndSettle();
      expect(find.textContaining('SPOT RESERVED FOR'), findsOneWidget);
      await t.tap(find.byKey(const Key('pay_now')));
      await t.pump(const Duration(milliseconds: 300));
      await t.pumpAndSettle();
      expect(find.text("You're Booked!"), findsOneWidget);
      expect(payments.verified.single.productId, 'event_ticket_199');
    });
  });
}
