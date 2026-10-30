import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/gradient_button.dart';
import '../domain/auth_models.dart';
import 'auth_controller.dart';

/// Figma: "WhatsApp-verify" (1898:6646). Figma shows 4 boxes; contract uses 6 digits.
class VerifyOtpScreen extends ConsumerStatefulWidget {
  const VerifyOtpScreen({super.key});

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen> {
  String _code = '';

  void _tap(String d) {
    if (_code.length < OtpRules.length) setState(() => _code += d);
  }

  void _back() {
    if (_code.isNotEmpty) setState(() => _code = _code.substring(0, _code.length - 1));
  }

  Future<void> _verify() async {
    final ok = await ref.read(authControllerProvider.notifier).verify(_code);
    if (!mounted) return;
    if (ok) {
      context.go(Routes.completeProfile);
    } else {
      setState(() => _code = '');
    }
  }

  String _fmt(int s) => '00:${s.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final phone = auth.phone ?? '';
    final display = phone.length == 13 ? '${phone.substring(0, 3)} ${phone.substring(3, 8)} ${phone.substring(8)}' : phone;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFCEFF6), Color(0xFFF7F2FE), Colors.white],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(children: [
            SizedBox(
              height: 56,
              child: Stack(alignment: Alignment.center, children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
                ),
                const Text('WhatsApp Verification', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              ]),
            ),
            const SizedBox(height: 28),
            const Text('Verify your WhatsApp', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('Enter the 6-digit code sent to your WhatsApp.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 12)],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.chat, size: 14, color: AppColors.whatsapp),
                  const SizedBox(width: 10),
                  Text(display, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 10),
                  const Icon(Icons.edit_outlined, size: 15, color: AppColors.violet),
                ]),
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(OtpRules.length, (i) {
                  final active = i == _code.length || (i == OtpRules.length - 1 && _code.length == OtpRules.length);
                  return Container(
                    key: Key('otpBox$i'),
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    width: 46,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: auth.error != null
                            ? AppColors.error
                            : active
                                ? AppColors.primary
                                : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 4))],
                    ),
                    child: Text(i < _code.length ? _code[i] : '',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),
            if (auth.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(auth.error!.message,
                    key: const Key('otpError'), style: const TextStyle(color: AppColors.error, fontSize: 13)),
              ),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text("Didn't receive code? ", style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              auth.resendIn > 0
                  ? Text('Resend in ${_fmt(auth.resendIn)}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.purple))
                  : GestureDetector(
                      onTap: auth.loading ? null : () => ref.read(authControllerProvider.notifier).resend(),
                      child: const Text('Resend code',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.purple)),
                    ),
            ]),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: GradientButton(
                key: const Key('verifyButton'),
                label: 'Verify & Continue',
                loading: auth.loading,
                onPressed: _code.length == OtpRules.length ? _verify : null,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.pop(),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Text('Change WhatsApp Number', style: TextStyle(fontSize: 13, color: AppColors.textBody)),
                Icon(Icons.chevron_right, size: 16, color: AppColors.textBody),
              ]),
            ),
            const Spacer(),
            _Keypad(onDigit: _tap, onBackspace: _back),
          ]),
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onDigit, required this.onBackspace});
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  static const _letters = ['', 'ABC', 'DEF', 'GHI', 'JKL', 'MNO', 'PQRS', 'TUV', 'WXYZ'];

  @override
  Widget build(BuildContext context) {
    Widget key(String d, String sub) => Expanded(
          child: InkWell(
            key: Key('key$d'),
            onTap: () => onDigit(d),
            child: SizedBox(
              height: 64,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(d, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w400)),
                if (sub.isNotEmpty)
                  Text(sub,
                      style: const TextStyle(
                          fontSize: 9, letterSpacing: 1.2, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              ]),
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(children: [
        for (var r = 0; r < 3; r++)
          Row(children: [for (var c = 1; c <= 3; c++) key('${r * 3 + c}', _letters[r * 3 + c - 1])]),
        Row(children: [
          const Expanded(child: SizedBox()),
          key('0', ''),
          Expanded(
            child: IconButton(
              key: const Key('keyBack'),
              onPressed: onBackspace,
              icon: const Icon(Icons.backspace_outlined),
            ),
          ),
        ]),
      ]),
    );
  }
}
