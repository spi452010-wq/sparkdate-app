enum EventStatus { upcoming, live, ended }

class SparkEvent {
  const SparkEvent({
    required this.id,
    required this.title,
    required this.city,
    required this.venue,
    required this.host,
    required this.startsAt,
    required this.pricePaise,
    required this.spotsLeft,
    required this.joined,
    required this.status,
    this.tag,
    this.roundInfo,
    this.playProductId,
    this.saved = false,
    this.booked = false,
  });

  final String id;
  final String title;
  final String city;
  final String venue;
  final String host;
  final DateTime startsAt;

  /// 0 = free event (skips billing).
  final int pricePaise;
  final int spotsLeft;
  final int joined;
  final EventStatus status;
  final String? tag;
  final String? roundInfo;

  /// Play consumable SKU, e.g. `event_ticket_199`.
  final String? playProductId;
  final bool saved;
  final bool booked;

  bool get isFree => pricePaise == 0;
  String get priceLabel => isFree ? 'Free' : '₹${pricePaise ~/ 100}';

  SparkEvent copyWith({bool? saved, bool? booked, int? spotsLeft}) => SparkEvent(
        id: id,
        title: title,
        city: city,
        venue: venue,
        host: host,
        startsAt: startsAt,
        pricePaise: pricePaise,
        spotsLeft: spotsLeft ?? this.spotsLeft,
        joined: joined,
        status: status,
        tag: tag,
        roundInfo: roundInfo,
        playProductId: playProductId,
        saved: saved ?? this.saved,
        booked: booked ?? this.booked,
      );

  factory SparkEvent.fromJson(Map<String, dynamic> j) => SparkEvent(
        id: j['id'] as String,
        title: j['title'] as String,
        city: j['city'] as String? ?? '',
        venue: j['venue'] as String? ?? '',
        host: j['hostName'] as String? ?? '',
        startsAt: DateTime.parse(j['startsAt'] as String),
        pricePaise: (j['pricePaise'] as num?)?.toInt() ?? 0,
        spotsLeft: (j['spotsLeft'] as num?)?.toInt() ?? 0,
        joined: (j['joinedCount'] as num?)?.toInt() ?? 0,
        status: EventStatus.values.byName(j['status'] as String? ?? 'upcoming'),
        tag: j['tag'] as String?,
        roundInfo: j['roundInfo'] as String?,
        playProductId: j['playProductId'] as String?,
        saved: j['saved'] as bool? ?? false,
        booked: j['booked'] as bool? ?? false,
      );
}

class EventFilter {
  const EventFilter({this.cities = const {}, this.status});
  final Set<String> cities;
  final EventStatus? status;

  bool matches(SparkEvent e) =>
      (cities.isEmpty || cities.contains(e.city)) && (status == null || e.status == status);
}

enum BookingStatus { pending, confirmed, refundRequested, refunded, cancelled }

/// POST /bookings -> pending booking with a 10-minute seat hold (paid) or confirmed (free).
class Booking {
  const Booking({required this.id, required this.eventId, required this.status, this.holdExpiresAt});
  final String id;
  final String eventId;
  final BookingStatus status;
  final DateTime? holdExpiresAt;

  factory Booking.fromJson(Map<String, dynamic> j) => Booking(
        id: j['id'] as String,
        eventId: j['eventId'] as String,
        status: BookingStatus.values.byName(j['status'] as String),
        holdExpiresAt: j['holdExpiresAt'] == null ? null : DateTime.parse(j['holdExpiresAt'] as String),
      );
}
