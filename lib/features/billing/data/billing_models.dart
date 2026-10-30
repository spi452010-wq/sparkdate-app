/// Google Play product ids (docs/ARCHITECTURE.md §7).
abstract final class BillingProducts {
  static const eventTicket199 = 'event_ticket_199';
  static const chatPassMonthly = 'chat_pass_monthly';
}

class PurchaseResult {
  const PurchaseResult({required this.productId, required this.purchaseToken, this.orderId});
  final String productId;
  final String purchaseToken;
  final String? orderId;
}
