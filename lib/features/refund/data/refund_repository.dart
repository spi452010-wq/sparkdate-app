import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';

enum RefundReason { noMatches, technicalIssue, leftEarly, other }

class RefundEligibility {
  const RefundEligibility({required this.bookingId, required this.eventTitle, required this.amountInr, required this.eligible});
  final String bookingId;
  final String eventTitle;
  final int amountInr;
  final bool eligible;
  factory RefundEligibility.fromJson(Map<String, dynamic> j) => RefundEligibility(
      bookingId: j['bookingId'] as String,
      eventTitle: j['eventTitle'] as String,
      amountInr: (j['amountInr'] as num).toInt(),
      eligible: j['eligible'] as bool);
}

class RefundRequest {
  const RefundRequest({required this.id, required this.status, required this.amountInr});
  final String id;
  final String status;
  final int amountInr;
  factory RefundRequest.fromJson(Map<String, dynamic> j) =>
      RefundRequest(id: j['id'] as String, status: j['status'] as String, amountInr: (j['amountInr'] as num).toInt());
}

/// Provisional (not in the API contract yet): GET /events/:id/refund-eligibility, POST /bookings/:id/refund.
/// The server refunds through the Play Developer API (orders.refund) for paid tickets.
abstract interface class RefundRepository {
  Future<RefundEligibility> eligibility(String eventId);
  Future<RefundRequest> request(String bookingId, RefundReason reason, {String? note});
}

class MockRefundRepository implements RefundRepository {
  final requested = <String>[];
  @override
  Future<RefundEligibility> eligibility(String eventId) async =>
      RefundEligibility(bookingId: 'bk_$eventId', eventTitle: 'Friday Night Speed Dating', amountInr: 199, eligible: true);
  @override
  Future<RefundRequest> request(String bookingId, RefundReason reason, {String? note}) async {
    if (requested.contains(bookingId)) throw const ApiException(ApiErrorCode.refundNotEligible);
    requested.add(bookingId);
    return RefundRequest(id: 'rf_$bookingId', status: 'processing', amountInr: 199);
  }
}

class RemoteRefundRepository implements RefundRepository {
  RemoteRefundRepository(this._dio);
  final Dio _dio;
  @override
  Future<RefundEligibility> eligibility(String eventId) async {
    try {
      return RefundEligibility.fromJson((await _dio.get<Map<String, dynamic>>('/events/$eventId/refund-eligibility')).data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<RefundRequest> request(String bookingId, RefundReason reason, {String? note}) async {
    try {
      final r = await _dio.post<Map<String, dynamic>>('/bookings/$bookingId/refund',
          data: {'reason': reason.name, if (note != null && note.isNotEmpty) 'note': note},
          options: Options(headers: {'Idempotency-Key': 'refund_$bookingId'}));
      return RefundRequest.fromJson(r.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
