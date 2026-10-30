import 'dart:async';

import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
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

  Future<void> confirm() async {
    busy.value = true;
    try {
      final me = await _profile.getMe();
      if (me.verificationStatus == 'none' || me.verificationStatus == 'rejected') {
        await Get.toNamed(Routes.selfie, arguments: event);
        return;
      }
      await _events.book(event.id);
      Get.offNamed(Routes.bookingSuccess, arguments: {'event': event, 'free': true});
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
        await _events.book(e.id);
        Get.offNamed(Routes.bookingSuccess, arguments: {'event': e, 'free': true});
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

/// Event Payment: POST /bookings (10-min seat hold) -> Play purchase -> /payments/play/verify.
class PaymentController extends GetxController {
  PaymentController(this._events, this._billing, this._payments, this._api);
  final EventsRepository _events;
  final BillingService _billing;
  final PaymentsRepository _payments;
  final ApiClient _api;

  late final SparkEvent event = Get.arguments as SparkEvent;
  final booking = Rxn<Booking>();
  final method = PayMethod.upi.obs;
  final remaining = Duration.zero.obs;
  final busy = false.obs;
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    _hold();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  Future<void> _hold() async {
    try {
      final b = await _events.book(event.id);
      booking.value = b;
      _tick();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    } catch (e) {
      showError(e);
    }
  }

  void _tick() {
    final end = booking.value?.holdExpiresAt;
    if (end == null) return;
    final d = end.difference(DateTime.now());
    remaining.value = d.isNegative ? Duration.zero : d;
    if (d.isNegative) _timer?.cancel();
  }

  bool get expired => booking.value?.holdExpiresAt != null && remaining.value == Duration.zero;

  Future<void> pay() async {
    final b = booking.value;
    if (b == null) return;
    if (expired) return showError(const ApiException(ApiErrorCode.bookingExpired));
    busy.value = true;
    try {
      final purchase = await _billing.buyEventTicket(
          productId: event.playProductId ?? BillingProducts.eventTicket199, userId: _api.userId.value ?? '', bookingId: b.id);
      await _payments.verifyPlayPurchase(purchase, bookingId: b.id);
      Get.offNamed(Routes.bookingSuccess, arguments: {'event': event, 'free': false, 'bookingId': b.id});
    } catch (e) {
      showError(e);
    } finally {
      busy.value = false;
    }
  }
}
