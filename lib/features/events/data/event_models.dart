/// App-side event state. API `status` is published|live|ended|cancelled; `published` = [upcoming].
enum EventStatus { upcoming, live, ended, cancelled }

EventStatus _eventStatus(String? s) => switch (s) {
      'live' => EventStatus.live,
      'ended' => EventStatus.ended,
      'cancelled' => EventStatus.cancelled,
      _ => EventStatus.upcoming,
    };

DateTime? _date(Object? v) => v == null ? null : DateTime.parse(v as String);

/// `appEvent` from docs/api/SPRINT2_API.md (+ `myBooking`, `liked`, `saved` on GET /events/:id).
class SparkEvent {
  const SparkEvent({
    required this.id,
    required this.title,
    required this.city,
    required this.startsAt,
    required this.pricePaise,
    required this.spotsLeft,
    required this.status,
    this.description = '',
    this.endsAt,
    this.roundMinutes = 3,
    this.playProductId,
    this.liked = false,
    this.saved = false,
    this.myBooking,
    // Design-only fields not in the API yet (see report): kept for the Figma layout, mock-filled.
    this.venue = '',
    this.host = '',
    this.joined,
    this.tag,
    this.roundInfo,
    bool? booked,
  }) : _booked = booked;

  final String id;
  final String title;
  final String city;
  final String description;
  final DateTime startsAt;
  final DateTime? endsAt;
  final int roundMinutes;

  /// `priceInPaise`; 0 = free event (skips billing).
  final int pricePaise;

  /// `seatsLeft` for the caller's gender; null when the caller has no gender yet.
  final int? spotsLeft;
  final EventStatus status;

  /// Play consumable SKU, e.g. `event_ticket_199`.
  final String? playProductId;
  final bool liked;
  final bool saved;
  final Booking? myBooking;

  final String venue;
  final String host;
  final int? joined;
  final String? tag;
  final String? roundInfo;
  final bool? _booked;

  bool get isFree => pricePaise == 0;
  String get priceLabel => isFree ? 'Free' : '₹${pricePaise ~/ 100}';
  bool get booked => _booked ?? (myBooking?.isActive ?? false);

  SparkEvent copyWith({bool? saved, bool? liked, bool? booked, int? spotsLeft, Booking? myBooking}) => SparkEvent(
        id: id,
        title: title,
        city: city,
        description: description,
        startsAt: startsAt,
        endsAt: endsAt,
        roundMinutes: roundMinutes,
        pricePaise: pricePaise,
        spotsLeft: spotsLeft ?? this.spotsLeft,
        status: status,
        playProductId: playProductId,
        liked: liked ?? this.liked,
        saved: saved ?? this.saved,
        myBooking: myBooking ?? this.myBooking,
        venue: venue,
        host: host,
        joined: joined,
        tag: tag,
        roundInfo: roundInfo,
        booked: booked ?? _booked,
      );

  factory SparkEvent.fromJson(Map<String, dynamic> j) => SparkEvent(
        id: j['id'] as String,
        title: j['title'] as String,
        city: j['city'] as String? ?? '',
        description: j['description'] as String? ?? '',
        startsAt: DateTime.parse(j['startsAt'] as String),
        endsAt: _date(j['endsAt']),
        roundMinutes: (j['roundMinutes'] as num?)?.toInt() ?? 3,
        pricePaise: (j['priceInPaise'] as num?)?.toInt() ?? 0,
        spotsLeft: (j['seatsLeft'] as num?)?.toInt(),
        status: _eventStatus(j['status'] as String?),
        playProductId: j['playProductId'] as String?,
        liked: j['liked'] as bool? ?? false,
        saved: j['saved'] as bool? ?? false,
        myBooking: j['myBooking'] == null ? null : Booking.fromJson(j['myBooking'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'city': city.isEmpty ? null : city,
        'description': description,
        'startsAt': startsAt.toUtc().toIso8601String(),
        'endsAt': endsAt?.toUtc().toIso8601String(),
        'roundMinutes': roundMinutes,
        'priceInPaise': pricePaise,
        'isFree': isFree,
        'playProductId': playProductId,
        'status': status == EventStatus.upcoming ? 'published' : status.name,
        'seatsLeft': spotsLeft,
      };
}

class EventFilter {
  const EventFilter({this.cities = const {}, this.status, this.q});
  final Set<String> cities;

  /// Only upcoming|live are listable (`GET /events?status=`).
  final EventStatus? status;
  final String? q;

  bool matches(SparkEvent e) =>
      (cities.isEmpty || cities.contains(e.city)) &&
      (status == null || e.status == status) &&
      (q == null || e.title.toLowerCase().contains(q!.toLowerCase()));
}

class EventPage {
  const EventPage(this.items, this.nextCursor);
  final List<SparkEvent> items;
  final String? nextCursor;
}

enum BookingStatus { pending, confirmed, cancelled, expired, refundRequested, refunded, cancelledByAdmin, unknown }

BookingStatus bookingStatusFrom(String? s) => switch (s) {
      'pending' => BookingStatus.pending,
      'confirmed' => BookingStatus.confirmed,
      'cancelled' => BookingStatus.cancelled,
      'expired' => BookingStatus.expired,
      'refund_requested' => BookingStatus.refundRequested,
      'refunded' => BookingStatus.refunded,
      'cancelled_by_admin' => BookingStatus.cancelledByAdmin,
      _ => BookingStatus.unknown,
    };

String bookingStatusToJson(BookingStatus s) => switch (s) {
      BookingStatus.refundRequested => 'refund_requested',
      BookingStatus.cancelledByAdmin => 'cancelled_by_admin',
      _ => s.name,
    };

enum RefundStatus { requested, processing, processed, rejected, failed }

class BookingRefund {
  const BookingRefund({required this.status, this.reason, this.rejectReason, this.requestedAt});
  final RefundStatus status;
  final String? reason;
  final String? rejectReason;
  final DateTime? requestedAt;
  factory BookingRefund.fromJson(Map<String, dynamic> j) => BookingRefund(
        status: RefundStatus.values.byName(j['status'] as String),
        reason: j['reason'] as String?,
        rejectReason: j['rejectReason'] as String?,
        requestedAt: _date(j['requestedAt']),
      );
  Map<String, dynamic> toJson() => {
        'status': status.name,
        'reason': reason,
        'rejectReason': rejectReason,
        'requestedAt': requestedAt?.toUtc().toIso8601String(),
      };
}

/// `bookingOut` from the API.
class Booking {
  const Booking({
    required this.id,
    required this.eventId,
    required this.status,
    this.gender,
    this.amountInPaise = 0,
    this.holdExpiresAt,
    this.confirmedAt,
    this.refundEligible = false,
    this.refund,
    this.createdAt,
    this.event,
  });
  final String id;
  final String eventId;
  final BookingStatus status;
  final String? gender;
  final int amountInPaise;

  /// Only set while `pending` (seat hold; extended while a UPI/pending purchase settles).
  final DateTime? holdExpiresAt;
  final DateTime? confirmedAt;
  final bool refundEligible;
  final BookingRefund? refund;
  final DateTime? createdAt;
  final SparkEvent? event;

  bool get isActive => status == BookingStatus.pending || status == BookingStatus.confirmed;

  factory Booking.fromJson(Map<String, dynamic> j) => Booking(
        id: j['id'] as String,
        eventId: j['eventId'] as String,
        status: bookingStatusFrom(j['status'] as String?),
        gender: j['gender'] as String?,
        amountInPaise: (j['amountInPaise'] as num?)?.toInt() ?? 0,
        holdExpiresAt: _date(j['holdExpiresAt']),
        confirmedAt: _date(j['confirmedAt']),
        refundEligible: j['refundEligible'] as bool? ?? false,
        refund: j['refund'] == null ? null : BookingRefund.fromJson(j['refund'] as Map<String, dynamic>),
        createdAt: _date(j['createdAt']),
        event: j['event'] == null ? null : SparkEvent.fromJson(j['event'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'eventId': eventId,
        'status': bookingStatusToJson(status),
        'gender': gender,
        'amountInPaise': amountInPaise,
        'holdExpiresAt': status == BookingStatus.pending ? holdExpiresAt?.toUtc().toIso8601String() : null,
        'confirmedAt': confirmedAt?.toUtc().toIso8601String(),
        'refundEligible': refundEligible,
        'refund': refund?.toJson(),
        'createdAt': createdAt?.toUtc().toIso8601String(),
        if (event != null) 'event': event!.toJson(),
      };
}

/// `play` block of POST /bookings: pass to BillingFlowParams.
class PlayPurchaseParams {
  const PlayPurchaseParams({required this.productId, required this.obfuscatedAccountId, this.obfuscatedProfileId});
  final String productId;
  final String obfuscatedAccountId;
  /// Dropped by the server in 79b4c97; tolerated if an older server still sends it.
  final String? obfuscatedProfileId;
  factory PlayPurchaseParams.fromJson(Map<String, dynamic> j) => PlayPurchaseParams(
        productId: j['productId'] as String,
        obfuscatedAccountId: j['obfuscatedAccountId'] as String,
        obfuscatedProfileId: j['obfuscatedProfileId'] as String?,
      );
  Map<String, dynamic> toJson() =>
      {'productId': productId, 'obfuscatedAccountId': obfuscatedAccountId, if (obfuscatedProfileId != null) 'obfuscatedProfileId': obfuscatedProfileId};
}

/// POST /bookings → `201 {booking, play?}` (new) or `200 {booking}` (already active).
class BookingResult {
  const BookingResult({required this.booking, this.play, this.created = true});
  final Booking booking;
  final PlayPurchaseParams? play;
  final bool created;
  factory BookingResult.fromJson(Map<String, dynamic> j, {bool created = true}) => BookingResult(
        booking: Booking.fromJson(j['booking'] as Map<String, dynamic>),
        play: j['play'] == null ? null : PlayPurchaseParams.fromJson(j['play'] as Map<String, dynamic>),
        created: created,
      );
}

/// GET /me/bookings.
class MyBookings {
  const MyBookings({this.upcoming = const [], this.past = const []});
  final List<Booking> upcoming;
  final List<Booking> past;
  factory MyBookings.fromJson(Map<String, dynamic> j) => MyBookings(
        upcoming: (j['upcoming'] as List).map((e) => Booking.fromJson(e as Map<String, dynamic>)).toList(),
        past: (j['past'] as List).map((e) => Booking.fromJson(e as Map<String, dynamic>)).toList(),
      );
}
