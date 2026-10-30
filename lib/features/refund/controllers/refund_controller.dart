import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/ui.dart';
import '../data/refund_repository.dart';

/// Refund 01 (eligibility, shown when an event ends with 0 completed dates) → 02 (reason + confirm) → 03 (done).
/// One permanent-for-the-flow controller shared by the three screens.
class RefundController extends GetxController {
  RefundController(this.eventId);
  final String eventId;
  final _repo = Get.find<RefundRepository>();
  final info = Rxn<RefundEligibility>();
  final reason = RefundReason.noMatches.obs;
  final note = TextEditingController();
  final busy = false.obs;
  final result = Rxn<RefundRequest>();

  @override
  void onInit() {
    super.onInit();
    _repo.eligibility(eventId).then((e) => info.value = e, onError: showError);
  }

  Future<void> submit() async {
    final i = info.value;
    if (i == null || busy.value) return;
    busy.value = true;
    try {
      result.value = await _repo.request(i.bookingId, reason.value, note: note.text.trim());
      Get.offNamed(Routes.refundDone);
    } catch (e) {
      showError(e);
    } finally {
      busy.value = false;
    }
  }

  void finish() {
    Get.offAllNamed(Routes.home);
    Future.microtask(() => Get.delete<RefundController>(force: true));
  }

  @override
  void onClose() {
    note.dispose();
    super.onClose();
  }
}
