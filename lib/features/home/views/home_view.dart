import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/ui.dart';
import '../../events/data/event_models.dart';
import '../../events/views/event_card.dart';
import '../controllers/home_controller.dart';

/// Home Dashboard (Figma 5581).
class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        bottomNavigationBar: const AppBottomNav(current: NavTab.home),
        body: SafeArea(
          child: Obx(() => RefreshIndicator(
                onRefresh: controller.load,
                child: ListView(padding: const EdgeInsets.all(20), children: [
                  Row(children: [
                    Expanded(
                      child: Text('Hi, ${controller.name.value} ✨',
                          key: const Key('home_greeting'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    ),
                    IconButton(
                      key: const Key('open_notifications'),
                      icon: const Icon(Icons.notifications_none_rounded),
                      onPressed: () => Get.toNamed(Routes.notifications),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  if (controller.next != null) _NextEventCard(event: controller.next!),
                  const SizedBox(height: 16),
                  TextField(
                    readOnly: true,
                    onTap: () => Get.offAllNamed(Routes.events),
                    decoration: InputDecoration(
                      hintText: 'Search events, cities…',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusField), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SectionHeader('More Live Events', action: 'See all', onAction: () => Get.offAllNamed(Routes.events)),
                  SizedBox(
                    height: 120,
                    child: ListView(scrollDirection: Axis.horizontal, children: [
                      for (final e in controller.live)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: SizedBox(
                            width: 200,
                            child: AppCard(
                              onTap: () => Get.toNamed(Routes.eventDetail, arguments: e),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                const Pill('LIVE', color: AppColors.primary, filled: true),
                                const SizedBox(height: 6),
                                Text(e.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                                Text('${e.city} • ${e.priceLabel}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ]),
                            ),
                          ),
                        ),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  AppCard(
                    onTap: () => Get.offAllNamed(Routes.profile),
                    child: Row(children: [
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(value: controller.completion.value, color: AppColors.violet, backgroundColor: AppColors.surfaceTint),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Complete Profile ${(controller.completion.value * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.w700)),
                          const Text('Better profiles get more mutual matches', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ]),
                      ),
                      const Icon(Icons.chevron_right),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  const SectionHeader('Your Upcoming Events'),
                  if (controller.upcoming.isEmpty) const Text('No bookings yet — find an event you like!'),
                  for (final e in controller.upcoming)
                    EventCard(event: e, onOpen: () => Get.toNamed(Routes.eventDetail, arguments: e)),
                ]),
              )),
        ),
      );
}

class _NextEventCard extends StatefulWidget {
  const _NextEventCard({required this.event});
  final SparkEvent event;
  @override
  State<_NextEventCard> createState() => _NextEventCardState();
}

class _NextEventCardState extends State<_NextEventCard> {
  Timer? _t;
  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    final d = e.startsAt.difference(DateTime.now());
    final live = e.status == EventStatus.live || d.isNegative;
    final label = live ? 'LIVE NOW' : 'STARTS IN ${d.inHours.toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(gradient: AppColors.ctaGradient, borderRadius: BorderRadius.circular(AppSpacing.radiusCard)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Pill('SEAT CONFIRMED', color: Colors.white),
          const Spacer(),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
        ]),
        const SizedBox(height: 12),
        Text(e.title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
        Text('${e.city} • ${fmtWhen(e.startsAt)}', style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 12),
        ElevatedButton(
          key: const Key('join_live'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary, shape: const StadiumBorder()),
          onPressed: () => Get.toNamed(Routes.waitingRoom, arguments: e),
          child: const Text('Join Live Event', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}
