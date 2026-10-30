/// Google Play Billing (via `in_app_purchase`) — interface only in Sprint 1.
///
/// - Paid event ticket = consumable product, e.g. [BillingProducts.eventTicket199].
/// - Chat Pass = subscription [BillingProducts.chatPassMonthly].
/// - Purchases pass obfuscatedAccountId = userId and obfuscatedProfileId = bookingId,
///   then the purchaseToken goes to POST /payments/play/verify (server acknowledges/consumes).
abstract final class BillingProducts {
  static const eventTicket199 = 'event_ticket_199';
  static const chatPassMonthly = 'chat_pass_monthly';
}

class PurchaseResult {
  const PurchaseResult({required this.productId, required this.purchaseToken});
  final String productId;
  final String purchaseToken;
}

abstract interface class BillingRepository {
  Future<bool> isAvailable();
  Future<PurchaseResult> buyEventTicket({required String productId, required String userId, required String bookingId});
  Future<PurchaseResult> subscribeChatPass({required String userId});
  Future<void> verifyWithServer(PurchaseResult purchase, {String? bookingId});
}
