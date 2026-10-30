import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/gradient_button.dart';
import '../domain/onboarding_page.dart';

/// Figma: "Onboarding 01" (1898:9348) and "Onboarding 02" (1898:9405)
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pc = PageController();
  int _index = 0;

  bool get _last => _index == onboardingPages.length - 1;

  void _next() {
    if (_last) {
      context.go(Routes.login);
    } else {
      _pc.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.splashBackground),
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 16, 0),
              child: Row(children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: AppColors.primary, width: 1.5),
                  ),
                  child: const Icon(Icons.favorite, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 8),
                const Text.rich(TextSpan(children: [
                  TextSpan(text: 'Spark', style: TextStyle(color: AppColors.textTitle)),
                  TextSpan(text: 'Date', style: TextStyle(color: AppColors.violet)),
                ]), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const Spacer(),
                TextButton(
                  key: const Key('skip'),
                  onPressed: () => context.go(Routes.login),
                  child: const Text('Skip',
                      style: TextStyle(color: Color(0xFF8A6D80), fontWeight: FontWeight.w600)),
                ),
              ]),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pc,
                itemCount: onboardingPages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => _Page(onboardingPages[i]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(onboardingPages.length, (i) {
                final on = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: on ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    color: on ? null : AppColors.divider,
                    gradient: on ? const LinearGradient(colors: [AppColors.magenta, AppColors.violet]) : null,
                  ),
                );
              }),
            ),
            const SizedBox(height: 36),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 110),
              child: GradientButton(
                key: const Key('onboardingNext'),
                label: _last ? 'Get Started' : 'Next',
                onPressed: _next,
              ),
            ),
            const SizedBox(height: 40),
          ]),
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page(this.p);
  final OnboardingPageData p;

  Widget _chip(String text, {Widget? lead}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.95),
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 8)],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (lead != null) ...[lead, const SizedBox(width: 6)],
          Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(children: [
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.7),
            borderRadius: BorderRadius.circular(36),
            boxShadow: const [BoxShadow(color: Color(0x1A8455EF), blurRadius: 30, offset: Offset(0, 12))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(fit: StackFit.expand, children: [
                Image.asset(p.image, fit: BoxFit.cover),
                Positioned(
                  top: 12,
                  left: 12,
                  child: _chip(p.topChip,
                      lead: Icon(Icons.circle,
                          size: 8, color: p.topChip.startsWith('Live') ? AppColors.primary : AppColors.success)),
                ),
                Positioned(bottom: 12, right: 12, child: _chip(p.bottomChip)),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFEDE6FB),
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            border: Border.all(color: const Color(0xFFDCD0F5)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(p.badgeIcon, size: 14, color: AppColors.purple),
            const SizedBox(width: 6),
            Text(p.badge,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.purple)),
          ]),
        ),
        const SizedBox(height: 16),
        Text(p.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26, height: 1.3, fontWeight: FontWeight.w800, letterSpacing: -.6)),
        const SizedBox(height: 12),
        Text(p.body,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, height: 1.6, color: AppColors.textBody)),
      ]),
    );
  }
}
