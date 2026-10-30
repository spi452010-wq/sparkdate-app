import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/gradient_button.dart';
import 'auth_controller.dart';

/// Figma: "Login — WhatsApp" (1898:6576)
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phone = TextEditingController();
  String? _localError;

  bool get _valid => RegExp(r'^[6-9]\d{9}$').hasMatch(_phone.text);

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!_valid) {
      setState(() => _localError = 'Enter a valid 10-digit mobile number');
      return;
    }
    setState(() => _localError = null);
    final ok = await ref.read(authControllerProvider.notifier).requestOtp('+91${_phone.text}');
    if (ok && mounted) context.push(Routes.verify);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final error = _localError ?? auth.error?.message;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go(Routes.onboarding),
        ),
        title: const Text('Login', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 64),
              const Text("Let's get you connected",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -.6)),
              const SizedBox(height: 12),
              const Text('Enter your WhatsApp number to start your\nspeed dating journey.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, height: 1.5, color: AppColors.textSecondary)),
              const SizedBox(height: 44),
              Row(children: [
                const Text('WhatsApp Number', style: TextStyle(fontSize: 13, color: AppColors.textBody)),
                const SizedBox(width: 6),
                const Icon(Icons.chat_bubble_outline, size: 14, color: AppColors.whatsapp),
                const Spacer(),
                Icon(Icons.lock_outline, size: 13, color: AppColors.crimson.withOpacity(.9)),
                const SizedBox(width: 4),
                const Text('Encrypted', style: TextStyle(fontSize: 12, color: AppColors.crimson)),
              ]),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.magenta, AppColors.violet]),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Container(
                  height: 54,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceTint,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                      ),
                      child: const Row(children: [
                        Text('🇮🇳', style: TextStyle(fontSize: 18)),
                        SizedBox(width: 8),
                        Text('+91', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                        Icon(Icons.keyboard_arrow_down, size: 18),
                      ]),
                    ),
                    Expanded(
                      child: TextField(
                        key: const Key('phoneField'),
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        onChanged: (_) => setState(() => _localError = null),
                        style: const TextStyle(fontSize: 17, letterSpacing: .5),
                        decoration: const InputDecoration(
                          hintText: '98765 43210',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 10),
              Row(children: [
                const Icon(Icons.circle, size: 7, color: AppColors.whatsapp),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    error ?? 'OTP will be sent directly to your WhatsApp',
                    style: TextStyle(
                        fontSize: 12, color: error != null ? AppColors.error : AppColors.textBody),
                  ),
                ),
              ]),
              const Spacer(),
              GradientButton(
                key: const Key('continueWhatsApp'),
                label: 'Continue with WhatsApp',
                loading: auth.loading,
                onPressed: _continue,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                key: const Key('googleSignIn'),
                onPressed: auth.loading
                    ? null
                    : () async {
                        final ok = await ref.read(authControllerProvider.notifier).signInWithGoogle();
                        if (ok && context.mounted) context.go(Routes.completeProfile);
                      },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: const StadiumBorder(),
                  side: const BorderSide(color: AppColors.divider),
                  foregroundColor: AppColors.textPrimary,
                ),
                icon: const Text('G',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF4285F4))),
                label: const Text('Continue with Google', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
