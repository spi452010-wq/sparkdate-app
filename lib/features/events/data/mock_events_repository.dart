import '../../../core/network/api_exception.dart';
import 'event_models.dart';
import 'events_repository.dart';

class MockEventsRepository implements EventsRepository {
  MockEventsRepository({this.latency = const Duration(milliseconds: 300), DateTime Function()? now})
      : _now = now ?? DateTime.now {
    final n = _now();
    _events = {
      for (final e in [
        SparkEvent(
            id: 'evt_1',
            title: 'Friday Night Speed Dating',
            city: 'Indore',
            venue: 'High Street Social, AB Road',
            host: 'Ananya',
            startsAt: n.subtract(const Duration(minutes: 15)),
            pricePaise: 24900,
            spotsLeft: 6,
            joined: 24,
            status: EventStatus.live,
            roundInfo: 'Round 2 of 5',
            playProductId: 'event_ticket_249'),
        SparkEvent(
            id: 'evt_2',
            title: 'Creatives & Introverts Mixer',
            city: 'Bhopal',
            venue: 'Artisan Alley Lounge',
            host: 'Ananya',
            startsAt: n.subtract(const Duration(minutes: 10)),
            pricePaise: 19900,
            spotsLeft: 4,
            joined: 18,
            status: EventStatus.live,
            roundInfo: '3-min micro dates',
            playProductId: 'event_ticket_199'),
        SparkEvent(
            id: 'evt_3',
            title: 'Tech & Founders Quick Sparks',
            city: 'Indore',
            venue: 'Sky Terrace Lounge',
            host: 'Tanvi M.',
            startsAt: n.subtract(const Duration(minutes: 25)),
            pricePaise: 29900,
            spotsLeft: 2,
            joined: 28,
            status: EventStatus.live,
            roundInfo: 'Round 3 of 5',
            playProductId: 'event_ticket_299'),
        SparkEvent(
            id: 'evt_4',
            title: 'Spontaneous Connection',
            city: 'Indore',
            venue: 'Virtual Lounge',
            host: 'Ananya',
            startsAt: n.add(const Duration(hours: 3)),
            pricePaise: 0,
            spotsLeft: 18,
            joined: 12,
            status: EventStatus.upcoming,
            tag: 'FIRST EVENT FREE'),
        SparkEvent(
            id: 'evt_5',
            title: 'Coffee & Connections',
            city: 'Mumbai',
            venue: 'Bandra Social',
            host: 'Tanvi M.',
            startsAt: n.add(const Duration(days: 2)),
            pricePaise: 19900,
            spotsLeft: 22,
            joined: 18,
            status: EventStatus.upcoming,
            tag: 'Casual Mixer',
            playProductId: 'event_ticket_199'),
        SparkEvent(
            id: 'evt_6',
            title: 'Weekend Sunset Rooftop Meetup',
            city: 'Bengaluru',
            venue: 'Rooftop 9',
            host: 'Ananya',
            startsAt: n.add(const Duration(days: 4)),
            pricePaise: 24900,
            spotsLeft: 10,
            joined: 24,
            status: EventStatus.upcoming,
            playProductId: 'event_ticket_249'),
      ])
        e.id: e,
    };
    // evt_1 is already booked by the mock user.
    _bookings['bkg_0'] = Booking(
        id: 'bkg_0', eventId: 'evt_1', status: BookingStatus.confirmed, amountInPaise: 24900, confirmedAt: n, createdAt: n);
  }

  final Duration latency;
  final DateTime Function() _now;
  late final Map<String, SparkEvent> _events;
  final _bookings = <String, Booking>{};
  final _idem = <String, Object>{};
  int _seq = 0;

  /// Keys seen on idempotent calls (tests).
  final idempotencyKeys = <String>[];

  /// Next booking hold length.
  Duration holdDuration = const Duration(minutes: 10);

  Future<void> _d() => latency == Duration.zero ? Future.value() : Future.delayed(latency);

  Booking? _active(String eventId) => _bookings.values.where((b) => b.eventId == eventId && b.isActive).firstOrNull;

  SparkEvent _view(SparkEvent e) => e.copyWith(myBooking: _active(e.id), booked: _active(e.id) != null);

  void _expireHolds() {
    for (final b in _bookings.values.toList()) {
      if (b.status == BookingStatus.pending && b.holdExpiresAt!.isBefore(_now())) {
        _bookings[b.id] = _copy(b, status: BookingStatus.expired);
        final e = _events[b.eventId]!;
        _events[b.eventId] = e.copyWith(spotsLeft: (e.spotsLeft ?? 0) + 1);
      }
    }
  }

  Booking _copy(Booking b,
          {BookingStatus? status, DateTime? holdExpiresAt, DateTime? confirmedAt, BookingRefund? refund, bool? refundEligible}) =>
      Booking(
        id: b.id,
        eventId: b.eventId,
        status: status ?? b.status,
        gender: b.gender,
        amountInPaise: b.amountInPaise,
        holdExpiresAt: (status ?? b.status) == BookingStatus.pending ? (holdExpiresAt ?? b.holdExpiresAt) : null,
        confirmedAt: confirmedAt ?? b.confirmedAt,
        refundEligible: refundEligible ?? b.refundEligible,
        refund: refund ?? b.refund,
        createdAt: b.createdAt,
      );

  Future<T> _idempotent<T extends Object>(String route, String key, Future<T> Function() f) async {
    if (!RegExp(r'^[A-Za-z0-9_\-:.]{8,128}$').hasMatch(key)) throw const ApiException(ApiErrorCode.idempotencyKeyRequired);
    idempotencyKeys.add(key);
    final k = '$route|$key';
    if (_idem.containsKey(k)) {
      final v = _idem[k]!;
      if (v is ApiException) throw v;
      return v as T;
    }
    if (_idem.keys.any((x) => x.endsWith('|$key'))) throw const ApiException(ApiErrorCode.idempotencyKeyReused);
    try {
      return _idem[k] = await f();
    } on ApiException catch (e) {
      _idem[k] = e;
      rethrow;
    }
  }

  @override
  Future<EventPage> page({EventFilter filter = const EventFilter(), String? cursor, int limit = 20}) async {
    await _d();
    _expireHolds();
    final all = _events.values.where(filter.matches).map(_view).toList()..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    final start = cursor == null ? 0 : int.parse(cursor);
    final end = (start + limit).clamp(0, all.length);
    return EventPage(all.sublist(start, end), end < all.length ? '$end' : null);
  }

  @override
  Future<List<SparkEvent>> list({EventFilter filter = const EventFilter()}) async =>
      (await page(filter: filter, limit: 50)).items;

  @override
  Future<SparkEvent> get(String id) async {
    await _d();
    _expireHolds();
    final e = _events[id] ?? (throw const ApiException(ApiErrorCode.notFound));
    return _view(e);
  }

  @override
  Future<SparkEvent> setLiked(String id, bool liked) async {
    await _d();
    _events[id] = (_events[id] ?? (throw const ApiException(ApiErrorCode.notFound))).copyWith(liked: liked);
    return _view(_events[id]!);
  }

  @override
  Future<SparkEvent> setSaved(String id, bool saved) async {
    await _d();
    _events[id] = (_events[id] ?? (throw const ApiException(ApiErrorCode.notFound))).copyWith(saved: saved);
    return _view(_events[id]!);
  }

  @override
  Future<List<SparkEvent>> savedEvents() async {
    await _d();
    return _events.values.where((e) => e.saved).map(_view).toList();
  }

  @override
  Future<BookingResult> book(String eventId, {required String idempotencyKey}) =>
      _idempotent('POST /bookings', idempotencyKey, () async {
        await _d();
        _expireHolds();
        final e = _events[eventId] ?? (throw const ApiException(ApiErrorCode.notFound));
        final existing = _active(eventId);
        if (existing != null) return BookingResult(booking: existing, created: false);
        if (e.status == EventStatus.ended || e.status == EventStatus.cancelled) {
          throw const ApiException(ApiErrorCode.eventNotBookable);
        }
        if ((e.spotsLeft ?? 0) <= 0) throw const ApiException(ApiErrorCode.eventFull);
        _events[eventId] = e.copyWith(spotsLeft: e.spotsLeft! - 1);
        final id = 'bkg_${++_seq}';
        final b = _bookings[id] = Booking(
          id: id,
          eventId: eventId,
          status: e.isFree ? BookingStatus.confirmed : BookingStatus.pending,
          amountInPaise: e.pricePaise,
          holdExpiresAt: e.isFree ? null : _now().add(holdDuration),
          confirmedAt: e.isFree ? _now() : null,
          createdAt: _now(),
        );
        return BookingResult(
          booking: b,
          play: e.isFree
              ? null
              : PlayPurchaseParams(
                  productId: e.playProductId ?? 'event_ticket_199', obfuscatedAccountId: 'u_mock', obfuscatedProfileId: id),
        );
      });

  /// Mock of what POST /payments/play/verify does to a booking (used by MockPaymentsRepository).
  Booking settle(String bookingId, {bool pending = false}) {
    _expireHolds();
    final b = _bookings[bookingId] ?? (throw const ApiException(ApiErrorCode.bookingNotFound));
    if (b.status == BookingStatus.confirmed) return b;
    if (b.status == BookingStatus.expired) {
      final e = _events[b.eventId]!;
      if ((e.spotsLeft ?? 0) <= 0) throw const ApiException(ApiErrorCode.eventFullRefunded);
      _events[b.eventId] = e.copyWith(spotsLeft: e.spotsLeft! - 1);
    }
    if (pending) {
      return _bookings[bookingId] =
          _copy(b, status: BookingStatus.pending, holdExpiresAt: _now().add(const Duration(minutes: 30)));
    }
    return _bookings[bookingId] = _copy(b, status: BookingStatus.confirmed, confirmedAt: _now(), refundEligible: true);
  }

  @override
  Future<Booking> cancelBooking(String bookingId) async {
    await _d();
    final b = _bookings[bookingId] ?? (throw const ApiException(ApiErrorCode.bookingNotFound));
    if (b.status != BookingStatus.pending) throw const ApiException(ApiErrorCode.bookingNotCancellable);
    final e = _events[b.eventId]!;
    _events[b.eventId] = e.copyWith(spotsLeft: (e.spotsLeft ?? 0) + 1);
    return _bookings[bookingId] = _copy(b, status: BookingStatus.cancelled);
  }

  @override
  Future<Booking> requestRefund(String bookingId, String reason, {required String idempotencyKey}) =>
      _idempotent('POST /bookings/:id/refund-request', idempotencyKey, () async {
        await _d();
        final b = _bookings[bookingId] ?? (throw const ApiException(ApiErrorCode.bookingNotFound));
        if (b.refund?.status == RefundStatus.rejected) throw const ApiException(ApiErrorCode.refundRejected);
        if (b.refund != null) throw const ApiException(ApiErrorCode.refundAlreadyRequested);
        if (!b.refundEligible) throw const ApiException(ApiErrorCode.refundNotEligible);
        return _bookings[bookingId] = _copy(b,
            status: BookingStatus.refundRequested,
            refundEligible: false,
            refund: BookingRefund(status: RefundStatus.requested, reason: reason, requestedAt: _now()));
      });

  @override
  Future<MyBookings> myBookings() async {
    await _d();
    _expireHolds();
    Booking withEvent(Booking b) => Booking.fromJson({...b.toJson(), 'event': _events[b.eventId]!.toJson()});
    final up = <Booking>[], past = <Booking>[];
    for (final b in _bookings.values) {
      final e = _events[b.eventId]!;
      (b.isActive && e.status != EventStatus.ended && e.status != EventStatus.cancelled ? up : past).add(withEvent(b));
    }
    return MyBookings(upcoming: up, past: past);
  }

  @override
  Future<List<SparkEvent>> myUpcoming() async {
    await _d();
    return _events.values.where((e) => _active(e.id) != null).map(_view).toList();
  }
}
