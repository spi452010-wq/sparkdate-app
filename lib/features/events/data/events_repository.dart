import 'event_models.dart';

/// docs/api/SPRINT2_API.md — Events (app) + Bookings.
abstract interface class EventsRepository {
  /// GET /events?status=upcoming|live&city=&q=&limit=&cursor= → `{items, nextCursor}`.
  Future<EventPage> page({EventFilter filter = const EventFilter(), String? cursor, int limit = 20});

  /// First page(s) for the selected filter. The API takes one city, so several cities are fetched in parallel.
  Future<List<SparkEvent>> list({EventFilter filter = const EventFilter()});

  /// GET /events/:id (+ myBooking, liked, saved).
  Future<SparkEvent> get(String id);

  /// POST|DELETE /events/:id/like.
  Future<SparkEvent> setLiked(String id, bool liked);

  /// POST|DELETE /events/:id/save.
  Future<SparkEvent> setSaved(String id, bool saved);

  /// GET /me/events/saved.
  Future<List<SparkEvent>> savedEvents();

  /// POST /bookings `{eventId}` with `Idempotency-Key`. Free → confirmed; paid → pending + seat hold + `play`.
  Future<BookingResult> book(String eventId, {required String idempotencyKey});

  /// DELETE /bookings/:id (pending only, releases the seat).
  Future<Booking> cancelBooking(String bookingId);

  /// POST /bookings/:id/refund-request `{reason}` with `Idempotency-Key`.
  Future<Booking> requestRefund(String bookingId, String reason, {required String idempotencyKey});

  /// GET /me/bookings → `{upcoming, past}`.
  Future<MyBookings> myBookings();

  /// Events of upcoming bookings (home dashboard).
  Future<List<SparkEvent>> myUpcoming();
}
