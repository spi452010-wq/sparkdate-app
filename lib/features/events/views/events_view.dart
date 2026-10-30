import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/gradient_button.dart';
import '../controllers/events_controllers.dart';
import '../data/event_models.dart';
import 'event_card.dart';

class EventsView extends GetView<EventsController> {
  const EventsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: const Text('Live Events', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(key: const Key('open_filter'), icon: const Icon(Icons.tune), onPressed: () => _openFilter(context)),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(current: NavTab.events),
      body: Obx(() => Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                for (final s in [EventStatus.upcoming, EventStatus.live])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: ChoiceChip(
                        key: Key('tab_${s.name}'),
                        label: SizedBox(width: double.infinity, child: Text(s == EventStatus.live ? 'Live' : 'Upcoming', textAlign: TextAlign.center)),
                        selected: controller.tab.value == s,
                        selectedColor: AppColors.violet.withOpacity(.15),
                        onSelected: (_) => controller.setTab(s),
                      ),
                    ),
                  ),
              ]),
            ),
            if (controller.cities.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('City: ${controller.cities.join(', ')}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ),
              ),
            Expanded(
              child: controller.loading.value && controller.events.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : controller.events.isEmpty
                      ? const Center(child: Text('No events match your filters'))
                      : RefreshIndicator(
                          onRefresh: controller.load,
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              for (final e in controller.events)
                                EventCard(
                                  event: e,
                                  onOpen: () => Get.toNamed(Routes.eventDetail, arguments: e),
                                  onSave: () => controller.toggleSave(e),
                                ),
                            ],
                          ),
                        ),
            ),
          ])),
    );
  }

  void _openFilter(BuildContext context) {
    controller.openFilter();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => const EventFilterSheet(),
    );
  }
}

/// "Filter Events" bottom sheet (CITY multi-select, Clear All, Apply Filters).
class EventFilterSheet extends GetView<EventsController> {
  const EventFilterSheet({super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Obx(() => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Row(children: [
                const Expanded(child: Text('Filter Events', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
                TextButton(key: const Key('clear_filter'), onPressed: controller.clearDraft, child: const Text('Clear All')),
              ]),
              const SizedBox(height: 8),
              const Text('CITY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final c in cityOptions)
                  FilterChip(
                    key: Key('city_$c'),
                    label: Text(c),
                    selected: controller.draftCities.contains(c),
                    selectedColor: AppColors.violet.withOpacity(.15),
                    checkmarkColor: AppColors.violet,
                    onSelected: (_) => controller.toggleDraftCity(c),
                  ),
              ]),
              const SizedBox(height: 24),
              GradientButton(
                key: const Key('apply_filter'),
                label: 'Apply Filters',
                onPressed: () {
                  controller.applyFilter();
                  Get.back<void>();
                },
              ),
            ])),
      );
}
