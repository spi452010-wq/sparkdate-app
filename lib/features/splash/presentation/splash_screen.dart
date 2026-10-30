import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/spark_logo.dart';

/// Figma: "Splash Screen" (1898:4569)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.duration = const Duration(seconds: 2)});
  final Duration duration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer(widget.duration, () {
      if (mounted) context.go(Routes.onboarding);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.splashBackground),
        child: Stack(children: [
          // Ambient glows
          Positioned(
            top: -52,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 384,
                height: 384,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: const Color(0xFFFFD8E7).withOpacity(.7), blurRadius: 64, spreadRadius: -40)],
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xB3FFD8E7), Color(0x66FFAFD3), Color(0x33DEE0FF)],
                  ),
                ),
              ),
            ),
          ),
          const Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              SparkLogoMark(),
              SizedBox(height: 28),
              SparkWordmark(),
              SizedBox(height: 16),
              Text('ONLINE SPEED DATING',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 1.68, color: AppColors.textMuted)),
            ]),
          ),
          Positioned(
            bottom: 131,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 70,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFFF35C7B), AppColors.violet]),
                  boxShadow: const [BoxShadow(color: Color(0x80FF4F7B), blurRadius: 12)],
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
