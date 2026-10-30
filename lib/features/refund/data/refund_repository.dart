import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../events/data/event_models.dart';

enum RefundReason {
  noMatches('No matches / dates did not happen'),
  technicalIssue('Technical issue during the event'),
  leftEarly('Had to leave early'),
  other('Other');

  const RefundReason(this.label);
  final String label;
}

/// Body `reason` (3–500 chars) for POST /bookings/:id/refund-request.
String refundReasonText(RefundReason r, String? note) {
  final n = note?.trim() ?? '';
  final s = n.isEmpty ? r.label : '${r.label}: $n';
  return s.length > 500 ? s.substring(0, 500) : s;
}

/// Derived from GET /events/:id `myBooking` (there is no separate eligibility endpoint).
class RefundEligibility {
  const RefundEligibility({required this.bookingId, required this.eventTitle, required this.amountInr, required this.eligible});
  final String bookingId;
  final String eventTitle;
  final int amountInr;
  final bool eligible;

  factory RefundEligibility.fromEvent(SparkEvent e) {
    final b = e.myBooking;
    if (b == null) throw const ApiException(ApiErrorCode.bookingNotFound);
    return RefundEligibility(bookingId: b.id, eventTitle: e.title, amountInr: b.amountInPaise ~/ 100, eligible: b.refundEligible);
  }
}

/// The booking's `refund` block after POST /bookings/:id/refund-request.
class RefundRequest {
  const RefundRequest({required this.id, required this.status, required this.amountInr, this.booking});
  final String id;
  final RefundStatus status;
  final int amountInr;
  final Booking? booking;

  factory RefundRequest.fromBooking(Booking b) =>
      RefundRequest(id: b.id, status: b.refund?.status ?? RefundStatus.requested, amountInr: b.amountInPaise ~/ 100, booking: b);
}

/// docs/api/SPRINT2_API.md: POST /bookings/:id/refund-request `{reason}` + Idempotency-Key → `{booking}`.
/// Errors: REFUND_NOT_ELIGIBLE, REFUND_ALREADY_REQUESTED, REFUND_REJECTED, BOOKING_NOT_FOUND.
abstract interface class RefundRepository {
  Future<RefundEligibility> eligibility(String eventId);
  Future<RefundRequest> request(String bookingId, RefundReason reason, {String? note, required String idempotencyKey});
}

class MockRefundRepository implements RefundRepository {
  final requested = <String>[];
  final keys = <String>[];
  final reasons = <String>[];
  @override
  Future<RefundEligibility> eligibility(String eventId) async =>
      RefundEligibility(bookingId: 'bk_$eventId', eventTitle: 'Friday Night Speed Dating', amountInr: 199, eligible: true);
  @override
  Future<RefundRequest> request(String bookingId, RefundReason reason, {String? note, required String idempotencyKey}) async {
    keys.add(idempotencyKey);
    if (requested.contains(bookingId)) throw const ApiException(ApiErrorCode.refundAlreadyRequested);
    requested.add(bookingId);
    reasons.add(refundReasonText(reason, note));
    return RefundRequest.fromBooking(Booking(
      id: bookingId,
      eventId: bookingId.replaceFirst('bk_', ''),
      status: BookingStatus.refundRequested,
      amountInPaise: 19900,
      refund: BookingRefund(status: RefundStatus.requested, reason: reasons.last, requestedAt: DateTime.now()),
    ));
  }
}

class RemoteRefundRepository implements RefundRepository {
  RemoteRefundRepository(this._dio);
  final Dio _dio;
  @override
  Future<RefundEligibility> eligibility(String eventId) async {
    try {
      return RefundEligibility.fromEvent(SparkEvent.fromJson((await _dio.get<Map<String, dynamic>>('/events/$eventId')).data!));
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<RefundRequest> request(String bookingId, RefundReason reason, {String? note, required String idempotencyKey}) async {
    try {
      final r = await _dio.post<Map<String, dynamic>>('/bookings/$bookingId/refund-request',
          data: {'reason': refundReasonText(reason, note)}, options: Options(headers: {'Idempotency-Key': idempotencyKey}));
      return RefundRequest.fromBooking(Booking.fromJson(r.data!['booking'] as Map<String, dynamic>));
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
