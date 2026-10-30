import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import 'event_models.dart';
import 'events_repository.dart';

/// Endpoints follow docs/ARCHITECTURE.md modules (events, bookings). Event/booking JSON
/// shapes are provisional until the Sprint 2 contract doc lands.
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

  List<SparkEvent> _list(Response<Map<String, dynamic>> r) =>
      (r.data!['items'] as List).cast<Map<String, dynamic>>().map(SparkEvent.fromJson).toList();

  @override
  Future<List<SparkEvent>> list({EventFilter filter = const EventFilter()}) => _run(() async => _list(
      await _dio.get<Map<String, dynamic>>('/events', queryParameters: {
        if (filter.cities.isNotEmpty) 'city': filter.cities.join(','),
        if (filter.status != null) 'status': filter.status!.name,
      })));

  @override
  Future<SparkEvent> get(String id) =>
      _run(() async => SparkEvent.fromJson((await _dio.get<Map<String, dynamic>>('/events/$id')).data!));

  @override
  Future<SparkEvent> setSaved(String id, bool saved) => _run(() async {
        saved ? await _dio.put<void>('/events/$id/save') : await _dio.delete<void>('/events/$id/save');
        return get(id);
      });

  @override
  Future<Booking> book(String eventId) => _run(() async => Booking.fromJson((await _dio.post<Map<String, dynamic>>(
        '/bookings',
        data: {'eventId': eventId},
        options: Options(headers: {'Idempotency-Key': 'book_${eventId}_${DateTime.now().millisecondsSinceEpoch ~/ 60000}'}),
      ))
          .data!));

  @override
  Future<List<SparkEvent>> myUpcoming() =>
      _run(() async => _list(await _dio.get<Map<String, dynamic>>('/bookings/me', queryParameters: {'status': 'upcoming'})));
}
