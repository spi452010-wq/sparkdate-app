import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/ui.dart';
import '../controllers/events_controllers.dart';
import '../data/event_models.dart';
import 'event_card.dart';

/// Free Event Booking (FIRST EVENT FREE, ₹99 → ₹0).
class FreeBookingView extends GetView<FreeBookingController> {
  const FreeBookingView({super.key});

  @override
  Widget build(BuildContext context) {
    final e = controller.event;
    return Scaffold(
      appBar: simpleAppBar('Free Event Booking'),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const Center(child: Pill('FIRST EVENT FREE', color: AppColors.success, filled: true, icon: Icons.card_giftcard)),
        const SizedBox(height: 16),
        Text(e.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        AppCard(
          child: Column(children: [
            KeyValueRow('When', fmtWhen(e.startsAt)),
            KeyValueRow('Where', '${e.venue}, ${e.city}'),
            const Divider(),
            const Row(children: [
              Expanded(child: Text('Event Pass', style: TextStyle(color: AppColors.textSecondary))),
              Text('₹99', style: TextStyle(decoration: TextDecoration.lineThrough, color: AppColors.textSecondary)),
              SizedBox(width: 8),
              Text('₹0', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.success)),
            ]),
          ]),
        ),
        const SizedBox(height: 16),
        const Text('A quick selfie check keeps every event safe and verified. It takes under a minute.',
            textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
      ]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Obx(() => GradientButton(key: const Key('confirm_free'), label: 'Book Free Event', loading: controller.busy.value, onPressed: controller.confirm)),
        ),
      ),
    );
  }
}

/// Free Event Selfie Verification.
class SelfieView extends GetView<SelfieController> {
  const SelfieView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: simpleAppBar('Selfie Verification'),
        body: Obx(() {
          final p = controller.selfiePath.value;
          return ListView(padding: const EdgeInsets.all(24), children: [
            const Text('Take a quick selfie', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('Your selfie is only used for verification and is never shown on your profile.',
                textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            Center(
              child: GestureDetector(
                key: const Key('selfie_capture'),
                onTap: controller.capture,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceTint,
                    border: Border.all(color: AppColors.violet, width: 3),
                    image: p == null ? null : DecorationImage(image: FileImage(File(p)), fit: BoxFit.cover),
                  ),
                  child: p == null ? const Icon(Icons.camera_alt_outlined, size: 56, color: AppColors.violet) : null,
                ),
              ),
            ),
            const SizedBox(height: 16),
            for (final t in const ['Good lighting, face the camera', 'No sunglasses or masks', 'Only you in the frame'])
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(children: [const Icon(Icons.check, size: 16, color: AppColors.success), const SizedBox(width: 8), Expanded(child: Text(t))]),
              ),
          ]);
        }),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Obx(() => controller.selfiePath.value == null
                ? GradientButton(label: 'Open Camera', onPressed: controller.capture)
                : GradientButton(key: const Key('selfie_submit'), label: 'Submit & Book', loading: controller.busy.value, onPressed: controller.submit)),
          ),
        ),
      );
}

/// Event Payment ("SPOT RESERVED FOR 09:41", UPI/Card/Net Banking, Pay ₹X via Google Play).
class PaymentView extends GetView<PaymentController> {
  const PaymentView({super.key});

  @override
  Widget build(BuildContext context) {
    final e = controller.event;
    return Scaffold(
      appBar: simpleAppBar('Event Payment'),
      body: Obx(() {
        final r = controller.remaining.value;
        final mm = r.inMinutes.toString().padLeft(2, '0');
        final ss = (r.inSeconds % 60).toString().padLeft(2, '0');
        return ListView(padding: const EdgeInsets.all(20), children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(.08), borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              const Icon(Icons.timer_outlined, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  switch (controller.state.value) {
                    PayState.holding => 'Reserving your spot…',
                    PayState.expired => 'SPOT HOLD EXPIRED',
                    PayState.pending => 'PAYMENT PENDING • SPOT HELD FOR $mm:$ss',
                    PayState.failed => 'Could not reserve a spot',
                    _ => 'SPOT RESERVED FOR $mm:$ss',
                  },
                  key: const Key('hold_timer'),
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(children: [
              KeyValueRow('Event', e.title),
              KeyValueRow('When', fmtWhen(e.startsAt)),
              const Divider(),
              KeyValueRow('Total', e.priceLabel, bold: true),
            ]),
          ),
          const SizedBox(height: 20),
          const Text('Payment method', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          for (final m in PayMethod.values)
            RadioListTile<PayMethod>(
              value: m,
              groupValue: controller.method.value,
              onChanged: (v) => controller.method.value = v!,
              activeColor: AppColors.violet,
              title: Text(const {PayMethod.upi: 'UPI', PayMethod.card: 'Card', PayMethod.netBanking: 'Net Banking'}[m]!),
            ),
          const Text('Payment is processed securely by Google Play.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ]);
      }),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Obx(() => GradientButton(
                key: const Key('pay_now'),
                label: switch (controller.state.value) {
                  PayState.expired => 'Hold expired — Book again',
                  PayState.failed => 'Try again',
                  PayState.pending => 'Check payment status',
                  _ => 'Pay ${e.priceLabel}',
                },
                loading: controller.busy.value || controller.state.value == PayState.holding,
                onPressed: switch (controller.state.value) {
                  PayState.holding || PayState.paying => null,
                  PayState.failed => controller.hold,
                  PayState.pending => controller.refreshStatus,
                  _ => controller.pay,
                },
              )),
        ),
      ),
    );
  }
}

/// Booking Successful ("You're Booked!") and Free Booking Successful ("Identity Check Required").
class BookingSuccessView extends StatelessWidget {
  const BookingSuccessView({super.key});

  @override
  Widget build(BuildContext context) {
    final args = (Get.arguments as Map?) ?? const {};
    final e = args['event'] as SparkEvent?;
    final free = args['free'] == true;
    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(24), children: [
          const SizedBox(height: 24),
          StatusHero(
            icon: Icons.check_rounded,
            title: "You're Booked!",
            subtitle: free
                ? 'Identity Check Required — your selfie is being reviewed. We\'ll notify you once you\'re verified.'
                : 'Your seat is confirmed. Smart Matching Active — we\'ll pair you with compatible singles.',
          ),
          const SizedBox(height: 24),
          if (e != null)
            AppCard(
              child: Column(children: [
                KeyValueRow('Event', e.title),
                KeyValueRow('Time slot', fmtWhen(e.startsAt)),
                KeyValueRow('Venue', '${e.venue}, ${e.city}'),
                const KeyValueRow('Attendee', '1 person'),
                KeyValueRow('Paid', free ? '₹0 (Free)' : e.priceLabel, bold: true),
              ]),
            ),
          const SizedBox(height: 24),
          GradientButton(key: const Key('success_home'), label: 'Go to Home', onPressed: () => Get.offAllNamed(Routes.home)),
          TextButton(onPressed: () => Get.offAllNamed(Routes.events), child: const Text('Browse more events')),
        ]),
      ),
    );
  }
}
