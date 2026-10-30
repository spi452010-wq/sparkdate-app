import 'dart:async';

import 'package:clock/clock.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/idempotency.dart';
import '../../../core/widgets/ui.dart';
import '../../billing/data/billing_models.dart';
import '../../billing/data/payments_repository.dart';
import '../../billing/services/billing_service.dart';
import '../../profile/data/profile_repository.dart';
import '../data/event_models.dart';
import '../data/events_repository.dart';

const cityOptions = ['Indore', 'Bhopal', 'Ahmedabad', 'Mumbai', 'Bengaluru'];

/// Events — Live Events list with Upcoming/Live tabs and the city filter bottom sheet.
class EventsController extends GetxController {
  EventsController(this._repo);
  final EventsRepository _repo;

  final events = <SparkEvent>[].obs;
  final loading = false.obs;
  final tab = EventStatus.live.obs;
  final cities = <String>{}.obs;

  /// Draft selection inside the open filter sheet (applied on "Apply Filters").
  final draftCities = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    try {
      events.assignAll(await _repo.list(filter: EventFilter(cities: cities.toSet(), status: tab.value)));
    } catch (e) {
      showError(e);
    } finally {
      loading.value = false;
    }
  }

  void setTab(EventStatus s) {
    tab.value = s;
    load();
  }

  void openFilter() => draftCities.assignAll(cities);
  void toggleDraftCity(String c) => draftCities.contains(c) ? draftCities.remove(c) : draftCities.add(c);
  void clearDraft() => draftCities.clear();

  void applyFilter() {
    cities.assignAll(draftCities);
    load();
  }

  Future<void> toggleSave(SparkEvent e) async {
    final i = events.indexWhere((x) => x.id == e.id);
    if (i < 0) return;
    events[i] = e.copyWith(saved: !e.saved); // optimistic
    try {
      events[i] = await _repo.setSaved(e.id, !e.saved);
    } catch (err) {
      events[i] = e;
      showError(err);
    }
  }
}

/// Event Details & Booking (+ Like/save).
class EventDetailController extends GetxController {
  EventDetailController(this._repo);
  final EventsRepository _repo;
  final event = Rxn<SparkEvent>();

  @override
  void onInit() {
    super.onInit();
    final a = Get.arguments;
    if (a is SparkEvent) event.value = a;
    final id = a is SparkEvent ? a.id : a as String?;
    if (id != null) _load(id);
  }

  Future<void> _load(String id) async {
    try {
      event.value = await _repo.get(id);
    } catch (e) {
      showError(e);
    }
  }

  Future<void> toggleLike() async {
    final e = event.value;
    if (e == null) return;
    event.value = e.copyWith(liked: !e.liked);
    try {
      event.value = await _repo.setLiked(e.id, !e.liked);
    } catch (err) {
      event.value = e;
      showError(err);
    }
  }

  Future<void> toggleSave() async {
    final e = event.value;
    if (e == null) return;
    event.value = e.copyWith(saved: !e.saved);
    try {
      event.value = await _repo.setSaved(e.id, !e.saved);
    } catch (err) {
      event.value = e;
      showError(err);
    }
  }

  void book() {
    final e = event.value;
    if (e == null) return;
    Get.toNamed(e.isFree ? Routes.freeBooking : Routes.payment, arguments: e);
  }
}

/// Free Event Booking -> Selfie Verification (if not verified) -> Free Booking Successful.
class FreeBookingController extends GetxController {
  FreeBookingController(this._events, this._profile);
  final EventsRepository _events;
  final ProfileRepository _profile;
  late final SparkEvent event = Get.arguments as SparkEvent;
  final busy = false.obs;
  final _book = IdempotentAction();

  Future<void> confirm() async {
    busy.value = true;
    try {
      final me = await _profile.getMe();
      if (me.verificationStatus == 'none' || me.verificationStatus == 'rejected') {
        await Get.toNamed(Routes.selfie, arguments: event);
        return;
      }
      await _book.run((k) => _events.book(event.id, idempotencyKey: k));
      Get.offNamed(Routes.bookingSuccess, arguments: {'event': event, 'free': true});
    } on ApiException catch (e) {
      if (e.error == ApiErrorCode.verificationRequired) {
        await Get.toNamed(Routes.selfie, arguments: event);
      } else {
        showError(e);
      }
    } catch (e) {
      showError(e);
    } finally {
      busy.value = false;
    }
  }
}

/// Free Event Selfie Verification: capture -> /media/selfie -> /profile/me/verification -> book.
class SelfieController extends GetxController {
  SelfieController(this._profile, this._events, {ImagePicker? picker}) : _picker = picker ?? ImagePicker();
  final ProfileRepository _profile;
  final EventsRepository _events;
  final ImagePicker _picker;
  late final SparkEvent? event = Get.arguments as SparkEvent?;
  final selfiePath = RxnString();
  final busy = false.obs;
  final _book = IdempotentAction();

  Future<void> capture() async {
    try {
      final f = await _picker.pickImage(source: ImageSource.camera, preferredCameraDevice: CameraDevice.front, maxWidth: 1600, imageQuality: 85);
      if (f != null) selfiePath.value = f.path;
    } catch (_) {
      showError(const ApiException(ApiErrorCode.unknown));
    }
  }

  Future<void> submit() async {
    final p = selfiePath.value;
    if (p == null) return;
    busy.value = true;
    try {
      await _profile.submitSelfie(p);
      final e = event;
      if (e != null) {
        try {
          await _book.run((k) => _events.book(e.id, idempotencyKey: k));
          Get.offNamed(Routes.bookingSuccess, arguments: {'event': e, 'free': true});
        } on ApiException catch (err) {
          // Selfie is reviewed by an admin; booking unlocks once approved.
          if (err.error != ApiErrorCode.verificationRequired) rethrow;
          Get.back<void>();
          showError(err);
        }
      } else {
        Get.back<void>();
      }
    } catch (e) {
      showError(e);
    } finally {
      busy.value = false;
    }
  }
}

enum PayMethod { upi, card, netBanking }

/// UI state of the payment screen.
enum PayState { holding, ready, paying, pending, expired, failed }

/// Event Payment: POST /bookings (seat hold + `play` params) -> Play purchase -> POST /payments/play/verify.
/// Each user action carries one Idempotency-Key, reused on retry (network/5xx/PLAY_UNAVAILABLE/IN_PROGRESS).
class PaymentController extends GetxController {
  PaymentController(this._events, this._billing, this._payments, this._api, {this.pollEvery = const Duration(seconds: 5)});
  final EventsRepository _events;
  final BillingService _billing;
  final PaymentsRepository _payments;
  final ApiClient _api;
  final Duration pollEvery;

  late final SparkEvent event = Get.arguments as SparkEvent;
  final booking = Rxn<Booking>();
  final method = PayMethod.upi.obs;
  final remaining = Duration.zero.obs;
  final busy = false.obs;
  final state = PayState.holding.obs;
  PlayPurchaseParams? _play;
  PurchaseResult? _purchase;
  final _bookAction = IdempotentAction();
  final _verifyAction = IdempotentAction();
  Timer? _timer;
  Timer? _poll;

  @override
  void onInit() {
    super.onInit();
    hold();
  }

  @override
  void onClose() {
    _timer?.cancel();
    _poll?.cancel();
    super.onClose();
  }

  Future<void> hold() async {
    state.value = PayState.holding;
    try {
      final r = await _bookAction.run((k) => _events.book(event.id, idempotencyKey: k));
      _play = r.play ?? _play;
      _apply(r.booking);
    } catch (e) {
      state.value = PayState.failed;
      showError(e);
    }
  }

  void _apply(Booking b) {
    booking.value = b;
    switch (b.status) {
      case BookingStatus.confirmed:
        _done(b);
      case BookingStatus.pending:
        if (state.value != PayState.pending) state.value = PayState.ready;
        _tick();
        _timer?.cancel();
        _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
      case BookingStatus.expired:
        _expire();
      default:
        state.value = PayState.failed;
        showError(const ApiException(ApiErrorCode.eventNotBookable));
    }
  }

  void _expire() {
    _timer?.cancel();
    _poll?.cancel();
    remaining.value = Duration.zero;
    state.value = PayState.expired;
  }

  void _tick() {
    final end = booking.value?.holdExpiresAt;
    if (end == null) return;
    final d = end.difference(clock.now());
    remaining.value = d.isNegative ? Duration.zero : d;
    if (d.isNegative && state.value == PayState.ready) _expire();
  }

  bool get expired => state.value == PayState.expired;

  Future<void> pay() async {
    if (busy.value) return;
    if (expired) {
      // Hold expired: a new booking is a new user action → fresh key.
      _bookAction.reset();
      _verifyAction.reset();
      _purchase = null;
      return hold();
    }
    final b = booking.value;
    if (b == null) return;
    busy.value = true;
    state.value = PayState.paying;
    try {
      final play = _play;
      final p = _purchase ??= await _billing.buyEventTicket(
          productId: play?.productId ?? event.playProductId ?? BillingProducts.eventTicket199,
          userId: play?.obfuscatedAccountId ?? _api.userId.value ?? '',
          bookingId: b.id);
      final r = await _verifyAction
          .run((k) => _payments.verifyPlayPurchase(p, kind: PurchaseKind.ticket, bookingId: b.id, idempotencyKey: k));
      if (r.pending) {
        // UPI / pending purchase: server extended the hold; poll until Play settles.
        state.value = PayState.pending;
        if (r.booking != null) _apply(r.booking!);
        _startPolling();
      } else {
        _done(r.booking ?? b);
      }
    } on ApiException catch (e) {
      if (!e.retryable) _purchase = null;
      if (e.error == ApiErrorCode.eventFullRefunded || e.error == ApiErrorCode.bookingExpired) {
        _expire();
      } else if (e.error == ApiErrorCode.bookingNotPending) {
        // Already confirmed (e.g. by RTDN) or no longer pending: reload the real booking state.
        state.value = PayState.ready;
        showError(e);
        await refreshStatus();
        return;
      } else {
        state.value = PayState.ready;
      }
      showError(e);
    } catch (e) {
      state.value = PayState.ready;
      showError(e);
    } finally {
      busy.value = false;
    }
  }

  void _startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(pollEvery, (_) => refreshStatus());
  }

  /// Re-reads `myBooking` from GET /events/:id (pending → confirmed | expired).
  Future<void> refreshStatus() async {
    try {
      final b = (await _events.get(event.id)).myBooking;
      if (b == null) return;
      if (b.status == BookingStatus.confirmed) return _done(b);
      if (b.status == BookingStatus.expired || b.status == BookingStatus.cancelled) return _expire();
      booking.value = b;
    } catch (_) {}
  }

  void _done(Booking b) {
    _timer?.cancel();
    _poll?.cancel();
    if (isClosed) return;
    Get.offNamed(Routes.bookingSuccess, arguments: {'event': event, 'free': b.amountInPaise == 0, 'bookingId': b.id});
  }
}
