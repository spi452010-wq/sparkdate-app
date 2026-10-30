import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../network/api_exception.dart';
import '../theme/app_colors.dart';

/// Shared building blocks used across Sprint 2+ screens.
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.color = Colors.white, this.onTap});
  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          onTap: onTap,
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
              border: Border.all(color: AppColors.divider),
            ),
            child: child,
          ),
        ),
      );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textTitle))),
          if (action != null)
            TextButton(onPressed: onAction, child: Text(action!, style: const TextStyle(color: AppColors.violet, fontWeight: FontWeight.w600))),
        ]),
      );
}

class Pill extends StatelessWidget {
  const Pill(this.label, {super.key, this.color = AppColors.violet, this.filled = false, this.icon});
  final String label;
  final Color color;
  final bool filled;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: filled ? color : color.withOpacity(.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 12, color: filled ? Colors.white : color), const SizedBox(width: 4)],
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: filled ? Colors.white : color)),
        ]),
      );
}

class Avatar extends StatelessWidget {
  const Avatar(this.name, {super.key, this.size = 48, this.url});
  final String name;
  final double size;
  final String? url;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.ctaGradient,
          image: url == null ? null : DecorationImage(image: NetworkImage(url!), fit: BoxFit.cover),
        ),
        alignment: Alignment.center,
        child: url != null
            ? null
            : Text(name.isEmpty ? '?' : name[0].toUpperCase(),
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: size * .4)),
      );
}

class KeyValueRow extends StatelessWidget {
  const KeyValueRow(this.label, this.value, {super.key, this.bold = false});
  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: AppColors.textPrimary)),
          ),
        ]),
      );
}

/// Simple top bar with back arrow used by inner screens.
PreferredSizeWidget simpleAppBar(String title, {List<Widget>? actions}) => AppBar(
      backgroundColor: Colors.transparent,
      leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Get.back<void>()),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
      actions: actions,
    );

/// Big centered success / status hero (Booking Successful, Subscription Successful, Mutual Connection…).
class StatusHero extends StatelessWidget {
  const StatusHero({super.key, required this.icon, required this.title, this.subtitle, this.color = AppColors.success});
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color, border: Border.all(color: color.withOpacity(.2), width: 10)),
          child: Icon(icon, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 16),
        Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textTitle)),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(subtitle!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, height: 1.4)),
        ],
      ]);
}

void showError(Object e) {
  final msg = e is ApiException ? e.message : 'Something went wrong. Please try again.';
  Get.rawSnackbar(message: msg, backgroundColor: AppColors.error);
}
