import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import 'event_models.dart';
import 'events_repository.dart';

/// Real client for docs/api/SPRINT2_API.md (Events, Bookings).
class RemoteEventsRepository implements EventsRepository {
  RemoteEventsRepository(this._dio);
  final Dio _dio;

  Future<T> _run<T>(Future<T> Function() f) async {
    try {
      return await f();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  static Options _idem(String key) => Options(headers: {'Idempotency-Key': key});

  @override
  Future<EventPage> page({EventFilter filter = const EventFilter(), String? cursor, int limit = 20, String? city}) =>
      _run(() async {
        final r = await _dio.get<Map<String, dynamic>>('/events', queryParameters: {
          'status': filter.status == EventStatus.live ? 'live' : 'upcoming',
          if (city != null) 'city': city else if (filter.cities.length == 1) 'city': filter.cities.first,
          if (filter.q != null && filter.q!.isNotEmpty) 'q': filter.q,
          'limit': limit,
          if (cursor != null) 'cursor': cursor,
        });
        return EventPage(
          (r.data!['items'] as List).map((e) => SparkEvent.fromJson(e as Map<String, dynamic>)).toList(),
          r.data!['nextCursor'] as String?,
        );
      });

  @override
  Future<List<SparkEvent>> list({EventFilter filter = const EventFilter()}) async {
    if (filter.cities.length <= 1) return (await page(filter: filter)).items;
    final pages = await Future.wait(filter.cities.map((c) => page(filter: filter, city: c)));
    return pages.expand((p) => p.items).toList()..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  }

  @override
  Future<SparkEvent> get(String id) =>
      _run(() async => SparkEvent.fromJson((await _dio.get<Map<String, dynamic>>('/events/$id')).data!));

  Future<SparkEvent> _react(String id, String kind, bool on) => _run(() async {
        on ? await _dio.post<void>('/events/$id/$kind') : await _dio.delete<void>('/events/$id/$kind');
        return get(id);
      });

  @override
  Future<SparkEvent> setLiked(String id, bool liked) => _react(id, 'like', liked);

  @override
  Future<SparkEvent> setSaved(String id, bool saved) => _react(id, 'save', saved);

  @override
  Future<List<SparkEvent>> savedEvents() =>
      _run(() async => ((await _dio.get<Map<String, dynamic>>('/me/events/saved')).data!['items'] as List)
          .map((e) => SparkEvent.fromJson(e as Map<String, dynamic>).copyWith(saved: true))
          .toList());

  @override
  Future<BookingResult> book(String eventId, {required String idempotencyKey}) => _run(() async {
        final r = await _dio.post<Map<String, dynamic>>('/bookings', data: {'eventId': eventId}, options: _idem(idempotencyKey));
        return BookingResult.fromJson(r.data!, created: r.statusCode == 201);
      });

  @override
  Future<Booking> cancelBooking(String bookingId) => _run(() async => Booking.fromJson(
      (await _dio.delete<Map<String, dynamic>>('/bookings/$bookingId')).data!['booking'] as Map<String, dynamic>));

  @override
  Future<Booking> requestRefund(String bookingId, String reason, {required String idempotencyKey}) => _run(() async {
        final r = await _dio.post<Map<String, dynamic>>('/bookings/$bookingId/refund-request',
            data: {'reason': reason}, options: _idem(idempotencyKey));
        return Booking.fromJson(r.data!['booking'] as Map<String, dynamic>);
      });

  @override
  Future<MyBookings> myBookings() =>
      _run(() async => MyBookings.fromJson((await _dio.get<Map<String, dynamic>>('/me/bookings')).data!));

  @override
  Future<List<SparkEvent>> myUpcoming() async =>
      (await myBookings()).upcoming.where((b) => b.event != null).map((b) => b.event!.copyWith(myBooking: b)).toList();
}
