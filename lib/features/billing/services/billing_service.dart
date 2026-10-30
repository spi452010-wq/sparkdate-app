import 'dart:async';

import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/network/api_exception.dart';
import '../data/billing_models.dart';

/// Purchase flow abstraction so views/controllers never touch `in_app_purchase` directly.
abstract class BillingService extends GetxService {
  Future<bool> isAvailable();

  /// Consumable event ticket. obfuscatedAccountId = [userId]; [bookingId] is sent to the
  /// server with the token; the server matches obfuscatedAccountId to the user and takes bookingId from the body.
  Future<PurchaseResult> buyEventTicket({required String productId, required String userId, required String bookingId});

  /// Monthly Chat Pass subscription.
  Future<PurchaseResult> subscribeChatPass({required String userId});
}

class MockBillingService extends BillingService {
  MockBillingService({this.fail = false});
  bool fail;
  int _n = 0;

  @override
  Future<bool> isAvailable() async => true;

  Future<PurchaseResult> _buy(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (fail) throw const ApiException(ApiErrorCode.purchaseCancelled);
    return PurchaseResult(productId: id, purchaseToken: 'mock_token_${++_n}', orderId: 'GPA.mock-$_n');
  }

  @override
  Future<PurchaseResult> buyEventTicket({required String productId, required String userId, required String bookingId}) =>
      _buy(productId);

  @override
  Future<PurchaseResult> subscribeChatPass({required String userId}) => _buy(BillingProducts.chatPassMonthly);
}

/// Real Google Play Billing through `in_app_purchase`.
///
/// Acknowledge/consume is done by the SERVER after /payments/play/verify (ARCHITECTURE §7),
/// so tickets are bought with autoConsume=false and the client does not call completePurchase.
///
/// NOTE: `in_app_purchase_android` maps `applicationUserName` -> obfuscatedAccountId but does not
/// expose obfuscatedProfileId; bookingId therefore travels in the verify request body.
class PlayBillingService extends BillingService {
  final _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  final _pending = <String, Completer<PurchaseResult>>{};

  @override
  void onInit() {
    super.onInit();
    _sub = _iap.purchaseStream.listen(_onUpdates, onError: (Object _) {});
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  void _onUpdates(List<PurchaseDetails> list) {
    for (final p in list) {
      final c = _pending[p.productID];
      if (c == null || c.isCompleted) continue;
      switch (p.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          c.complete(PurchaseResult(
              productId: p.productID, purchaseToken: p.verificationData.serverVerificationData, orderId: p.purchaseID));
        case PurchaseStatus.canceled:
          c.completeError(const ApiException(ApiErrorCode.purchaseCancelled));
        case PurchaseStatus.error:
          c.completeError(const ApiException(ApiErrorCode.paymentFailed));
        case PurchaseStatus.pending:
          break;
      }
    }
  }

  @override
  Future<bool> isAvailable() => _iap.isAvailable();

  Future<ProductDetails> _product(String id) async {
    if (!await _iap.isAvailable()) throw const ApiException(ApiErrorCode.billingUnavailable);
    final r = await _iap.queryProductDetails({id});
    if (r.productDetails.isEmpty) throw const ApiException(ApiErrorCode.paymentFailed);
    return r.productDetails.first;
  }

  Future<PurchaseResult> _await(String id) {
    final c = Completer<PurchaseResult>();
    _pending[id] = c;
    return c.future.whenComplete(() => _pending.remove(id));
  }

  @override
  Future<PurchaseResult> buyEventTicket({required String productId, required String userId, required String bookingId}) async {
    final product = await _product(productId);
    final f = _await(productId);
    await _iap.buyConsumable(
        purchaseParam: PurchaseParam(productDetails: product, applicationUserName: userId), autoConsume: false);
    return f;
  }

  @override
  Future<PurchaseResult> subscribeChatPass({required String userId}) async {
    final product = await _product(BillingProducts.chatPassMonthly);
    final f = _await(product.id);
    await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product, applicationUserName: userId));
    return f;
  }
}
