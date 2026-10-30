import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/ui.dart';
import '../controllers/events_controllers.dart';
import '../data/event_models.dart';
import 'event_card.dart';

class EventDetailView extends GetView<EventDetailController> {
  const EventDetailView({super.key});

  @override
  Widget build(BuildContext context) => Obx(() {
        final e = controller.event.value;
        return Scaffold(
          appBar: simpleAppBar('Event Details', actions: [
            if (e != null)
              IconButton(
                key: const Key('detail_save'),
                icon: Icon(e.saved ? Icons.favorite : Icons.favorite_border, color: AppColors.primary),
                onPressed: controller.toggleSave,
              ),
          ]),
          body: e == null ? const Center(child: CircularProgressIndicator()) : _body(e),
          bottomNavigationBar: e == null
              ? null
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: Row(children: [
                      Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Event Pass', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        Text(e.priceLabel, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                      ]),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GradientButton(
                          key: const Key('book_event'),
                          label: e.booked ? 'Booked' : (e.isFree ? 'Book Free Event' : 'Book Now'),
                          onPressed: e.booked ? null : controller.book,
                        ),
                      ),
                    ]),
                  ),
                ),
        );
      });

  Widget _body(SparkEvent e) => ListView(padding: const EdgeInsets.all(20), children: [
        Container(
          height: 180,
          decoration: BoxDecoration(gradient: AppColors.splashBackground, borderRadius: BorderRadius.circular(AppSpacing.radiusCard)),
          alignment: Alignment.bottomLeft,
          padding: const EdgeInsets.all(14),
          child: Wrap(spacing: 6, children: [
            if (e.status == EventStatus.live) const Pill('LIVE NOW', color: AppColors.primary, filled: true),
            if (e.tag != null) Pill(e.tag!, filled: true),
          ]),
        ),
        const SizedBox(height: 16),
        Text(e.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textTitle)),
        const SizedBox(height: 8),
        Row(children: [
          Avatar(e.host, size: 32),
          const SizedBox(width: 8),
          Expanded(child: Text('Hosted by ${e.host}', style: const TextStyle(fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 12),
        KeyValueRow('When', fmtWhen(e.startsAt)),
        KeyValueRow('Where', '${e.venue}, ${e.city}'),
        const SizedBox(height: 12),
        Row(children: [
          _stat('${e.joined}', 'Joined'),
          _stat('${e.spotsLeft}', 'Spots left'),
          _stat('3 min', 'Per date'),
        ]),
        const SizedBox(height: 20),
        const Text('Zero-pressure matchmaking', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text('Meet verified singles in quick 3-minute video dates. Like or save after each round — '
            'if it\'s mutual, you\'ll connect.', style: TextStyle(color: AppColors.textBody, height: 1.4)),
        const SizedBox(height: 12),
        for (final b in const ['Verified profiles only', 'Smart matching by interests', 'Refund if you get no match'])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              const Icon(Icons.check_circle, color: AppColors.success, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(b)),
            ]),
          ),
      ]);

  Widget _stat(String v, String l) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: AppColors.surfaceTint, borderRadius: BorderRadius.circular(14)),
          child: Column(children: [
            Text(v, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            Text(l, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ]),
        ),
      );
}
