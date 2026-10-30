import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import 'billing_models.dart';

/// Server side of Play Billing: POST /payments/play/verify. The server verifies with the
/// Play Developer API, confirms the booking / activates the Chat Pass and acknowledges/consumes.
abstract interface class PaymentsRepository {
  Future<void> verifyPlayPurchase(PurchaseResult p, {String? bookingId});
}

class MockPaymentsRepository implements PaymentsRepository {
  final verified = <PurchaseResult>[];
  @override
  Future<void> verifyPlayPurchase(PurchaseResult p, {String? bookingId}) async => verified.add(p);
}

class RemotePaymentsRepository implements PaymentsRepository {
  RemotePaymentsRepository(this._dio);
  final Dio _dio;

  @override
  Future<void> verifyPlayPurchase(PurchaseResult p, {String? bookingId}) async {
    try {
      await _dio.post<void>('/payments/play/verify',
          data: {'productId': p.productId, 'purchaseToken': p.purchaseToken, if (bookingId != null) 'bookingId': bookingId},
          options: Options(headers: {'Idempotency-Key': 'verify_${p.purchaseToken.hashCode}'}));
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
