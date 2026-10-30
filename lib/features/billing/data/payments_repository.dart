import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../events/data/event_models.dart';
import '../../events/data/mock_events_repository.dart';
import 'billing_models.dart';

enum PurchaseKind { ticket, chatPass }

/// POST /payments/play/verify response.
/// ticket: 200 `{status:"confirmed", booking}` | 202 `{status:"pending", booking}` (UPI; hold extended).
/// chat_pass: 200 `{status:"confirmed", chatPassUntil}` | 202 `{status:"pending"}`.
class VerifyResult {
  const VerifyResult({required this.pending, this.booking, this.chatPassUntil});
  final bool pending;
  final Booking? booking;
  final DateTime? chatPassUntil;
  factory VerifyResult.fromJson(Map<String, dynamic> j) => VerifyResult(
        pending: j['status'] == 'pending',
        booking: j['booking'] == null ? null : Booking.fromJson(j['booking'] as Map<String, dynamic>),
        chatPassUntil: j['chatPassUntil'] == null ? null : DateTime.parse(j['chatPassUntil'] as String),
      );
}

/// GET /subscriptions/me → `{chatPass:{active, expiresAt, productId, autoRenewing, state}}`.
class ChatPassStatus {
  const ChatPassStatus({required this.active, this.expiresAt, this.productId, this.autoRenewing = false, this.state});
  final bool active;
  final DateTime? expiresAt;
  final String? productId;
  final bool autoRenewing;
  final String? state;
  factory ChatPassStatus.fromJson(Map<String, dynamic> j) {
    final c = (j['chatPass'] as Map<String, dynamic>?) ?? const {};
    return ChatPassStatus(
      active: c['active'] as bool? ?? false,
      expiresAt: c['expiresAt'] == null ? null : DateTime.parse(c['expiresAt'] as String),
      productId: c['productId'] as String?,
      autoRenewing: c['autoRenewing'] as bool? ?? false,
      state: c['state'] as String?,
    );
  }
}

/// Server side of Play Billing. The server verifies with the Play Developer API, confirms the
/// booking / activates the Chat Pass and acknowledges/consumes.
abstract interface class PaymentsRepository {
  /// [idempotencyKey] is one per purchase action and is reused on retry (see IdempotentAction).
  Future<VerifyResult> verifyPlayPurchase(PurchaseResult p,
      {required PurchaseKind kind, String? bookingId, required String idempotencyKey});

  Future<ChatPassStatus> subscription();
}

class MockPaymentsRepository implements PaymentsRepository {
  MockPaymentsRepository({this.events});
  final MockEventsRepository? events;
  final verified = <PurchaseResult>[];
  final keys = <String>[];

  /// Simulate UPI: next verify returns 202 pending.
  bool nextPending = false;
  DateTime? chatPassUntil;

  @override
  Future<VerifyResult> verifyPlayPurchase(PurchaseResult p,
      {required PurchaseKind kind, String? bookingId, required String idempotencyKey}) async {
    keys.add(idempotencyKey);
    final pending = nextPending;
    nextPending = false;
    if (kind == PurchaseKind.ticket) {
      final b = events?.settle(bookingId!, pending: pending);
      verified.add(p);
      return VerifyResult(pending: pending, booking: b);
    }
    verified.add(p);
    if (pending) return const VerifyResult(pending: true);
    chatPassUntil = DateTime.now().add(const Duration(days: 30));
    return VerifyResult(pending: false, chatPassUntil: chatPassUntil);
  }

  @override
  Future<ChatPassStatus> subscription() async => ChatPassStatus(
      active: chatPassUntil?.isAfter(DateTime.now()) ?? false,
      expiresAt: chatPassUntil,
      productId: 'chat_pass_monthly',
      state: 'active');
}

class RemotePaymentsRepository implements PaymentsRepository {
  RemotePaymentsRepository(this._dio);
  final Dio _dio;

  @override
  Future<VerifyResult> verifyPlayPurchase(PurchaseResult p,
      {required PurchaseKind kind, String? bookingId, required String idempotencyKey}) async {
    try {
      final r = await _dio.post<Map<String, dynamic>>('/payments/play/verify',
          data: {
            'purchaseToken': p.purchaseToken,
            'productId': p.productId,
            'kind': kind == PurchaseKind.ticket ? 'ticket' : 'chat_pass',
            if (bookingId != null) 'bookingId': bookingId,
          },
          options: Options(headers: {'Idempotency-Key': idempotencyKey}));
      return VerifyResult.fromJson(r.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<ChatPassStatus> subscription() async {
    try {
      return ChatPassStatus.fromJson((await _dio.get<Map<String, dynamic>>('/subscriptions/me')).data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
