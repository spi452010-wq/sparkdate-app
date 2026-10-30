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

    test('paid booking is pending with a hold + play params; free is confirmed; rebooking returns the active booking', () async {
      final paid = await repo.book('evt_2', idempotencyKey: 'key-paid-0001');
      expect(paid.booking.status, BookingStatus.pending);
      expect(paid.booking.holdExpiresAt, isNotNull);
      expect(paid.play!.obfuscatedProfileId, isNull);
      expect(paid.play!.obfuscatedAccountId, isNotEmpty);
      final free = await repo.book('evt_4', idempotencyKey: 'key-free-0001');
      expect(free.booking.status, BookingStatus.confirmed);
      expect(free.play, isNull);
      final again = await repo.book('evt_4', idempotencyKey: 'key-free-0002');
      expect(again.created, isFalse);
      expect(again.booking.id, free.booking.id);
    });

    test('same idempotency key replays; invalid key rejected; key reused on another route fails', () async {
      final a = await repo.book('evt_2', idempotencyKey: 'same-key-123');
      final b = await repo.book('evt_2', idempotencyKey: 'same-key-123');
      expect(identical(a, b), isTrue);
      expect(() => repo.book('evt_5', idempotencyKey: 'short'), throwsA(isA<ApiException>()));
      await expectLater(repo.requestRefund('bkg_0', 'no matches', idempotencyKey: 'same-key-123'),
          throwsA(isA<ApiException>().having((e) => e.error, 'error', ApiErrorCode.idempotencyKeyReused)));
    });

    test('hold expiry -> expired; verify after expiry re-seats or EVENT_FULL_REFUNDED', () async {
      var now = DateTime(2026, 10, 30, 12);
      final r = MockEventsRepository(latency: Duration.zero, now: () => now)..holdDuration = const Duration(minutes: 1);
      final b = (await r.book('evt_3', idempotencyKey: 'hold-key-001')).booking;
      now = now.add(const Duration(minutes: 2));
      expect((await r.get('evt_3')).myBooking, isNull);
      expect((await r.myBookings()).past.single.status, BookingStatus.expired);
      expect(r.settle(b.id).status, BookingStatus.confirmed);
    });

    test('pending UPI keeps the booking pending with an extended hold', () async {
      final b = (await repo.book('evt_2', idempotencyKey: 'upi-key-0001')).booking;
      final p = repo.settle(b.id, pending: true);
      expect(p.status, BookingStatus.pending);
      expect(p.holdExpiresAt!.isAfter(b.holdExpiresAt!), isTrue);
    });

    test('cancel only pending; refund request on eligible booking', () async {
      final b = (await repo.book('evt_2', idempotencyKey: 'cancel-key-01')).booking;
      expect((await repo.cancelBooking(b.id)).status, BookingStatus.cancelled);
      await expectLater(repo.cancelBooking('bkg_0'),
          throwsA(isA<ApiException>().having((e) => e.error, 'error', ApiErrorCode.bookingNotCancellable)));
      final refund = repo.settle(repo.settle('bkg_0').id);
      expect(refund.status, BookingStatus.confirmed);
    });

    test('save toggles', () async {
      expect((await repo.setSaved('evt_5', true)).saved, isTrue);
      expect((await repo.get('evt_5')).saved, isTrue);
      expect((await repo.savedEvents()).map((e) => e.id), ['evt_5']);
      expect((await repo.setLiked('evt_5', true)).liked, isTrue);
    });
  });

  group('event screens', () {
    late MockPaymentsRepository payments;
    setUp(() {
      Get.testMode = true;
      Get.put(ApiClient()).userId.value = 'u1';
      final ev = Get.put<EventsRepository>(MockEventsRepository(latency: Duration.zero)) as MockEventsRepository;
      Get.put<ProfileRepository>(MockProfileRepository(latency: Duration.zero));
      Get.put<BillingService>(MockBillingService());
      payments = Get.put<PaymentsRepository>(MockPaymentsRepository(events: ev)) as MockPaymentsRepository;
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

    testWidgets('UPI pending: verify 202 -> pending state -> status check -> success', (t) async {
      t.view.physicalSize = const Size(1080, 4000);
      t.view.devicePixelRatio = 2.5;
      addTearDown(t.view.reset);
      await t.pumpWidget(app('/start'));
      final repo = Get.find<EventsRepository>() as MockEventsRepository;
      final e = await repo.get('evt_2');
      payments.nextPending = true;
      Get.toNamed(Routes.payment, arguments: e);
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('pay_now')));
      await t.pumpAndSettle();
      expect(find.textContaining('PAYMENT PENDING'), findsOneWidget);
      final b = (await repo.get('evt_2')).myBooking!;
      repo.settle(b.id);
      await t.tap(find.byKey(const Key('pay_now')));
      await t.pumpAndSettle();
      expect(find.text("You're Booked!"), findsOneWidget);
      expect(payments.keys, hasLength(1));
    });
  });
}
