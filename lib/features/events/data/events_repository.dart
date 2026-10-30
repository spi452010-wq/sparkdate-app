import 'event_models.dart';

abstract interface class EventsRepository {
  Future<List<SparkEvent>> list({EventFilter filter = const EventFilter()});
  Future<SparkEvent> get(String id);

  /// Like/save toggle ("Like and save event").
  Future<SparkEvent> setSaved(String id, bool saved);

  /// POST /bookings (Idempotency-Key). Free -> confirmed, paid -> pending + seat hold.
  Future<Booking> book(String eventId);

  Future<List<SparkEvent>> myUpcoming();
}
