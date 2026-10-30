import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/ui.dart';
import '../data/event_models.dart';

String fmtWhen(DateTime d) {
  const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return '${d.day} ${m[d.month - 1]}, $h:${d.minute.toString().padLeft(2, '0')} ${d.hour < 12 ? 'AM' : 'PM'}';
}

class EventCard extends StatelessWidget {
  const EventCard({super.key, required this.event, required this.onOpen, this.onSave});
  final SparkEvent event;
  final VoidCallback onOpen;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final e = event;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AppCard(
        key: Key('event_${e.id}'),
        onTap: onOpen,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            height: 110,
            decoration: BoxDecoration(gradient: AppColors.splashBackground, borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.all(10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (e.status == EventStatus.live) const Pill('LIVE NOW', color: AppColors.primary, filled: true, icon: Icons.circle),
              if (e.tag != null) Pill(e.tag!, color: AppColors.violet, filled: true),
              const Spacer(),
              if (onSave != null)
                InkWell(
                  key: Key('save_${e.id}'),
                  onTap: onSave,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white,
                    child: Icon(e.saved ? Icons.favorite : Icons.favorite_border, size: 18, color: AppColors.primary),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: Text(e.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
            Text(e.priceLabel, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.place_outlined, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Expanded(
              child: Text('${e.city} • ${e.roundInfo ?? fmtWhen(e.startsAt)}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
                child: Text(e.joined == null ? e.priceLabel : '${e.joined} joined',
                    style: const TextStyle(fontSize: 12, color: AppColors.textBody))),
            if (e.spotsLeft != null)
              Pill('${e.spotsLeft} spots left', color: e.spotsLeft! <= 3 ? AppColors.crimson : AppColors.success),
            const SizedBox(width: 8),
            const Text('View Event', style: TextStyle(color: AppColors.violet, fontWeight: FontWeight.w700, fontSize: 12)),
          ]),
        ]),
      ),
    );
  }
}
