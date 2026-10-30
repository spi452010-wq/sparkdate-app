import '../../../core/network/api_exception.dart';
import 'event_models.dart';
import 'events_repository.dart';

class MockEventsRepository implements EventsRepository {
  MockEventsRepository({this.latency = const Duration(milliseconds: 300), DateTime Function()? now}) : _now = now ?? DateTime.now {
    final n = _now();
    _events = {
      for (final e in [
        SparkEvent(id: 'evt_1', title: 'Friday Night Speed Dating', city: 'Indore', venue: 'High Street Social, AB Road', host: 'Ananya', startsAt: n.subtract(const Duration(minutes: 15)), pricePaise: 24900, spotsLeft: 6, joined: 24, status: EventStatus.live, roundInfo: 'Round 2 of 5', playProductId: 'event_ticket_249', booked: true),
        SparkEvent(id: 'evt_2', title: 'Creatives & Introverts Mixer', city: 'Bhopal', venue: 'Artisan Alley Lounge', host: 'Ananya', startsAt: n.subtract(const Duration(minutes: 10)), pricePaise: 19900, spotsLeft: 4, joined: 18, status: EventStatus.live, roundInfo: '3-min micro dates', playProductId: 'event_ticket_199'),
        SparkEvent(id: 'evt_3', title: 'Tech & Founders Quick Sparks', city: 'Indore', venue: 'Sky Terrace Lounge', host: 'Tanvi M.', startsAt: n.subtract(const Duration(minutes: 25)), pricePaise: 29900, spotsLeft: 2, joined: 28, status: EventStatus.live, roundInfo: 'Round 3 of 5', playProductId: 'event_ticket_299'),
        SparkEvent(id: 'evt_4', title: 'Spontaneous Connection', city: 'Indore', venue: 'Virtual Lounge', host: 'Ananya', startsAt: n.add(const Duration(hours: 3)), pricePaise: 0, spotsLeft: 18, joined: 12, status: EventStatus.upcoming, tag: 'FIRST EVENT FREE'),
        SparkEvent(id: 'evt_5', title: 'Coffee & Connections', city: 'Mumbai', venue: 'Bandra Social', host: 'Tanvi M.', startsAt: n.add(const Duration(days: 2)), pricePaise: 19900, spotsLeft: 22, joined: 18, status: EventStatus.upcoming, tag: 'Casual Mixer', playProductId: 'event_ticket_199'),
        SparkEvent(id: 'evt_6', title: 'Weekend Sunset Rooftop Meetup', city: 'Bengaluru', venue: 'Rooftop 9', host: 'Ananya', startsAt: n.add(const Duration(days: 4)), pricePaise: 24900, spotsLeft: 10, joined: 24, status: EventStatus.upcoming, playProductId: 'event_ticket_249'),
      ])
        e.id: e,
    };
  }

  final Duration latency;
  final DateTime Function() _now;
  late final Map<String, SparkEvent> _events;
  int _seq = 0;

  Future<void> _d() => latency == Duration.zero ? Future.value() : Future.delayed(latency);

  @override
  Future<List<SparkEvent>> list({EventFilter filter = const EventFilter()}) async {
    await _d();
    return _events.values.where(filter.matches).toList();
  }

  @override
  Future<SparkEvent> get(String id) async {
    await _d();
    return _events[id] ?? (throw const ApiException(ApiErrorCode.unknown));
  }

  @override
  Future<SparkEvent> setSaved(String id, bool saved) async {
    await _d();
    return _events[id] = _events[id]!.copyWith(saved: saved);
  }

  @override
  Future<Booking> book(String eventId) async {
    await _d();
    final e = _events[eventId]!;
    if (e.booked) throw const ApiException(ApiErrorCode.alreadyBooked);
    if (e.spotsLeft <= 0) throw const ApiException(ApiErrorCode.eventFull);
    _events[eventId] = e.copyWith(booked: true, spotsLeft: e.spotsLeft - 1);
    return Booking(
      id: 'bkg_${++_seq}',
      eventId: eventId,
      status: e.isFree ? BookingStatus.confirmed : BookingStatus.pending,
      holdExpiresAt: e.isFree ? null : _now().add(const Duration(minutes: 10)),
    );
  }

  @override
  Future<List<SparkEvent>> myUpcoming() async {
    await _d();
    return _events.values.where((e) => e.booked).toList();
  }
}
