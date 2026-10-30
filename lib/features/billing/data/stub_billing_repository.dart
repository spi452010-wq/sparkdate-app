import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/billing_repository.dart';

/// Placeholder until a later sprint wires `in_app_purchase` (Google Play Billing).
class StubBillingRepository implements BillingRepository {
  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<PurchaseResult> buyEventTicket({required String productId, required String userId, required String bookingId}) =>
      throw UnimplementedError('Play Billing not wired yet');

  @override
  Future<PurchaseResult> subscribeChatPass({required String userId}) =>
      throw UnimplementedError('Play Billing not wired yet');

  @override
  Future<void> verifyWithServer(PurchaseResult purchase, {String? bookingId}) =>
      throw UnimplementedError('Play Billing not wired yet');
}

final billingRepositoryProvider = Provider<BillingRepository>((ref) => StubBillingRepository());
