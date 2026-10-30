import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/ui.dart';
import '../controllers/refund_controller.dart';
import '../data/refund_repository.dart';

/// Refund 01 — no dates completed, offer a refund.
class RefundView extends GetView<RefundController> {
  const RefundView({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(leading: IconButton(icon: const Icon(Icons.close), onPressed: controller.finish)),
        body: Obx(() {
          final i = controller.info.value;
          if (i == null) return const Center(child: CircularProgressIndicator());
          return ListView(padding: const EdgeInsets.all(24), children: [
            const StatusHero(
                icon: Icons.sentiment_dissatisfied,
                color: AppColors.violet,
                title: 'No dates this time',
                subtitle: "We couldn't find you a match during this event. You're eligible for a full refund."),
            const SizedBox(height: 24),
            AppCard(
              child: Column(children: [
                KeyValueRow('Event', i.eventTitle),
                KeyValueRow('Refund amount', '₹${i.amountInr}', bold: true),
                const KeyValueRow('Refund to', 'Original payment (Google Play)'),
              ]),
            ),
            const SizedBox(height: 24),
            if (i.eligible)
              GradientButton(
                  key: const Key('refund_start'), label: 'Request Refund', onPressed: () => Get.toNamed(Routes.refundConfirm)),
            TextButton(onPressed: controller.finish, child: const Text('Not now')),
          ]);
        }),
      );
}

/// Refund 02 — reason + confirm.
class RefundConfirmView extends GetView<RefundController> {
  const RefundConfirmView({super.key});
  static const _labels = {
    RefundReason.noMatches: 'I didn\'t get any matches',
    RefundReason.technicalIssue: 'Technical issue during the event',
    RefundReason.leftEarly: 'I had to leave early',
    RefundReason.other: 'Other',
  };
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: simpleAppBar('Request Refund'),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          const SectionHeader('Why are you requesting a refund?'),
          Obx(() => Column(
                children: RefundReason.values
                    .map((r) => RadioListTile<RefundReason>(
                          key: Key('reason_${r.name}'),
                          value: r,
                          groupValue: controller.reason.value,
                          onChanged: (v) => controller.reason.value = v!,
                          title: Text(_labels[r]!),
                        ))
                    .toList(),
              )),
          TextField(
              controller: controller.note, maxLines: 3, decoration: const InputDecoration(hintText: 'Anything else? (optional)')),
          const SizedBox(height: 24),
          Obx(() => GradientButton(
              key: const Key('refund_confirm'),
              label: controller.busy.value ? 'Submitting…' : 'Confirm Refund',
              onPressed: controller.busy.value ? null : controller.submit)),
        ]),
      );
}

/// Refund 03 — requested.
class RefundDoneView extends GetView<RefundController> {
  const RefundDoneView({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Obx(() => StatusHero(
                  icon: Icons.check,
                  title: 'Refund Requested',
                  subtitle: '₹${controller.result.value?.amountInr ?? ''} will be returned to your original payment method '
                      'within 5–7 business days.')),
              const SizedBox(height: 32),
              GradientButton(key: const Key('refund_home'), label: 'Back to Home', onPressed: controller.finish),
            ]),
          ),
        ),
      );
}
