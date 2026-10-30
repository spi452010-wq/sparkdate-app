import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../theme/app_colors.dart';

enum NavTab { home, events, live, chat, profile }

/// Bottom nav from Figma (Home • Events • Live • Chat • Profile) with raised Live button.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.current});
  final NavTab current;

  static const _routes = {
    NavTab.home: Routes.home,
    NavTab.events: Routes.events,
    NavTab.live: Routes.waitingRoom,
    NavTab.chat: Routes.chats,
    NavTab.profile: Routes.profile,
  };

  void _go(NavTab t) {
    if (t == current) return;
    if (t == NavTab.live) {
      Get.toNamed(Routes.waitingRoom);
    } else {
      Get.offAllNamed(_routes[t]!);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget item(NavTab t, IconData icon, String label) {
      final on = t == current;
      final color = on ? AppColors.violet : AppColors.textSecondary;
      return Expanded(
        child: InkWell(
          key: Key('nav_${t.name}'),
          onTap: () => _go(t),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: on ? FontWeight.w700 : FontWeight.w500)),
          ]),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 6, top: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, -4))],
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(children: [
        item(NavTab.home, Icons.home_rounded, 'Home'),
        item(NavTab.events, Icons.event_rounded, 'Events'),
        Expanded(
          child: GestureDetector(
            key: const Key('nav_live'),
            onTap: () => _go(NavTab.live),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.ctaGradient),
                child: const Icon(Icons.videocam_rounded, color: Colors.white),
              ),
              const Text('Live', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
        item(NavTab.chat, Icons.chat_bubble_rounded, 'Chat'),
        item(NavTab.profile, Icons.person_rounded, 'Profile'),
      ]),
    );
  }
}
