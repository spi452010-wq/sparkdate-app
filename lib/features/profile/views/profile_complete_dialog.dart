import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/gradient_button.dart';

/// Figma: "Complete Your Profile" success modal (1898:7394). Returns true for "Explore Events".
Future<bool?> showProfileCompleteDialog(BuildContext context) => showDialog<bool>(
      context: context,
      barrierColor: const Color(0x80000000),
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton.filledTonal(
                onPressed: () => Navigator.pop(ctx, false),
                icon: const Icon(Icons.close, size: 18),
              ),
            ),
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success,
                border: Border.all(color: const Color(0xFFD5F5EA), width: 8),
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 14),
            const Text('Profile Complete!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text("Your preferences are saved. You're ready to jump into live speed dating sessions.",
                textAlign: TextAlign.center, style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.textBody)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.surfaceTint, borderRadius: BorderRadius.circular(12)),
              child: Column(children: [
                const Row(children: [
                  Text('Profile Status', style: TextStyle(fontSize: 12)),
                  Spacer(),
                  Text('100% Completed',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.success)),
                ]),
                const SizedBox(height: 8),
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    gradient: const LinearGradient(colors: [AppColors.primary, AppColors.crimson, AppColors.purple]),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 14),
            for (final t in ['Instant Speed Matchmaking Unlocked', 'Priority Access to Live Lobbies'])
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  const Icon(Icons.check_circle, size: 16, color: AppColors.success),
                  const SizedBox(width: 10),
                  Text(t, style: const TextStyle(fontSize: 13)),
                ]),
              ),
            const SizedBox(height: 10),
            GradientButton(label: 'Explore Events', onPressed: () => Navigator.pop(ctx, true)),
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Stay on Profile', style: TextStyle(color: AppColors.textBody)),
            ),
          ]),
        ),
      ),
    );
