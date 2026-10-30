import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/gradient_button.dart';
import '../data/profile_models.dart';
import 'profile_complete_dialog.dart';
import '../controllers/profile_controller.dart';

const _cities = ['Indore', 'Bhopal', 'Mumbai', 'Delhi NCR', 'Bengaluru'];
const _fields = ['Software & Tech', 'Marketing & Growth', 'Finance & VC', 'Design & Creative', 'Product / SaaS'];

/// Figma: "Complete Your Profile" (1898:7215) + success modal (1898:7394)
class CompleteProfileView extends GetView<ProfileController> {
  const CompleteProfileView({super.key});

  Future<void> _pickPhoto(BuildContext context) async {
    try {
      final f = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
      if (f == null) return;
      final ext = f.path.toLowerCase();
      if (!(ext.endsWith('.jpg') || ext.endsWith('.jpeg') || ext.endsWith('.png') || ext.endsWith('.webp'))) {
        if (context.mounted) _snack(context, 'Only JPG, PNG or WEBP photos are allowed');
        return;
      }
      if (await f.length() > 8 * 1024 * 1024) {
        if (context.mounted) _snack(context, 'Photo must be under 8 MB');
        return;
      }
      controller.setDraft(controller.state.draft.copyWith(photoPath: f.path));
    } catch (_) {
      if (context.mounted) _snack(context, 'Could not open gallery');
    }
  }

  void _snack(BuildContext c, String m) => ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) => Obx(() => _build(context));

  Widget _build(BuildContext context) {
    final s = controller.state;
    final d = s.draft;
    final c = controller;
    final pct = ProfileValidator.completion(d);

    Widget err(String k) => s.errors[k] == null
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(s.errors[k]!, key: Key('err_$k'), style: const TextStyle(color: AppColors.error, fontSize: 12)),
          );

    return Scaffold(
      backgroundColor: const Color(0xFFFDF4FB),
      appBar: AppBar(
        centerTitle: false,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Get.offAllNamed(Routes.login)),
        title: const Text('Complete Your Profile', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(radius: 15, backgroundColor: AppColors.crimson, child: Icon(Icons.person_outline, size: 16, color: Colors.white)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
        children: [
          const Text('Tell us about yourself', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -.5)),
          const SizedBox(height: 6),
          const Text("Choose what you're looking for to personalize your speed matching sessions.",
              style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.textBody)),
          const SizedBox(height: 16),
          _Card(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('Profile completion', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('${(pct * 100).round()}%',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.crimson)),
              ]),
              const SizedBox(height: 10),
              _GradientBar(value: pct),
              const SizedBox(height: 10),
              const Text('Almost there! Complete your preferences for higher quality matches.',
                  style: TextStyle(fontSize: 12, height: 1.5, color: AppColors.textBody)),
            ]),
          ),
          const SizedBox(height: 20),
          // ---- Basic details (required by API contract) ----
          Center(
            child: GestureDetector(
              key: const Key('photoPicker'),
              onTap: () => _pickPhoto(context),
              child: CircleAvatar(
                radius: 46,
                backgroundColor: AppColors.surfaceTint,
                backgroundImage: d.photoPath != null ? FileImage(File(d.photoPath!)) : null,
                child: d.photoPath == null ? const Icon(Icons.add_a_photo_outlined, color: AppColors.violet) : null,
              ),
            ),
          ),
          Center(child: err('photo')),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('nameField'),
            initialValue: d.name,
            maxLength: 50,
            decoration: const InputDecoration(labelText: 'Full name', counterText: ''),
            onChanged: (v) => c.setDraft(d.copyWith(name: v)),
          ),
          err('name'),
          const SizedBox(height: 12),
          InkWell(
            key: const Key('dobField'),
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: d.dateOfBirth ?? DateTime(now.year - 24),
                firstDate: DateTime(now.year - 100),
                lastDate: now,
              );
              if (picked != null) c.setDraft(controller.state.draft.copyWith(dateOfBirth: picked));
            },
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Date of birth', suffixIcon: Icon(Icons.calendar_today_outlined, size: 18)),
              child: Text(d.dateOfBirth == null
                  ? 'Select'
                  : '${d.dateOfBirth!.day.toString().padLeft(2, '0')}/${d.dateOfBirth!.month.toString().padLeft(2, '0')}/${d.dateOfBirth!.year}'),
            ),
          ),
          err('dob'),
          const SizedBox(height: 12),
          Row(children: [
            for (final g in Gender.values) ...[
              Expanded(
                child: _SelectChip(
                  key: Key('gender_${g.name}'),
                  label: g == Gender.male ? 'Man' : 'Woman',
                  selected: d.gender == g,
                  onTap: () => c.setDraft(d.copyWith(gender: g)),
                ),
              ),
              if (g == Gender.male) const SizedBox(width: 12),
            ],
          ]),
          err('gender'),
          const SizedBox(height: 12),
          const Text('Interested in meeting', style: TextStyle(fontSize: 13, color: AppColors.textBody)),
          const SizedBox(height: 8),
          Row(children: [
            for (final g in Gender.values) ...[
              Expanded(
                child: _SelectChip(
                  key: Key('interestedIn_${g.name}'),
                  label: g == Gender.male ? 'Men' : 'Women',
                  selected: d.interestedIn == g,
                  onTap: () => c.setDraft(d.copyWith(interestedIn: g)),
                ),
              ),
              if (g == Gender.male) const SizedBox(width: 12),
            ],
          ]),
          err('interestedIn'),
          const SizedBox(height: 24),
          // ---- Figma sections ----
          const Row(children: [
            Expanded(child: Text('Interested City', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600))),
            Text('Location detected', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ]),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.violet.withOpacity(.6)),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: AppColors.surfaceTint, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.location_on_outlined, color: AppColors.violet, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(d.city, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
              const Icon(Icons.keyboard_arrow_down),
            ]),
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final city in _cities)
              _Pill(label: city, selected: d.city == city, onTap: () => c.setDraft(d.copyWith(city: city))),
          ]),
          const SizedBox(height: 24),
          const Row(children: [
            Expanded(child: Text('What are you interested in?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
            Text('Multi-select', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textBody)),
          ]),
          const SizedBox(height: 12),
          for (final (i, title, sub, icon, color) in [
            (Interest.dating, 'Dating', 'Romance', Icons.favorite, AppColors.crimson),
            (Interest.networking, 'Networking', 'Founders & professionals', Icons.work, AppColors.purple),
            (Interest.marriage, 'Marriage', 'Looking for marriage & lifelong commitment', Icons.favorite_border, AppColors.magenta),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _InterestCard(
                key: Key('interest_${i.name}'),
                title: title,
                subtitle: sub,
                icon: icon,
                color: color,
                isNew: i == Interest.marriage,
                selected: d.interests.contains(i),
                onTap: () {
                  final set = {...d.interests};
                  set.contains(i) ? set.remove(i) : set.add(i);
                  c.setDraft(d.copyWith(interests: set));
                },
              ),
            ),
          err('interests'),
          if (d.interests.contains(Interest.networking)) ...[
            const SizedBox(height: 8),
            _Card(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Text('Networking Focus', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  Spacer(),
                  Text('Select your fields', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ]),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final f in _fields)
                    _Pill(
                      label: f,
                      selected: d.networkingFields.contains(f),
                      dark: true,
                      onTap: () {
                        final set = {...d.networkingFields};
                        set.contains(f) ? set.remove(f) : set.add(f);
                        c.setDraft(d.copyWith(networkingFields: set));
                      },
                    ),
                ]),
                err('fields'),
              ]),
            ),
          ],
          const SizedBox(height: 24),
          if (s.apiError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(s.apiError!.message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error)),
            ),
          GradientButton(
            key: const Key('saveProfile'),
            label: 'Save & Continue',
            loading: s.saving,
            onPressed: () async {
              final ok = await c.submit();
              if (!context.mounted) return;
              if (ok) {
                final explore = await showProfileCompleteDialog(context);
                if (explore == true && context.mounted) Get.offAllNamed(Routes.home);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4))],
        ),
        child: child,
      );
}

class _GradientBar extends StatelessWidget {
  const _GradientBar({required this.value});
  final double value;
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 6,
          color: AppColors.surfaceTint,
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: value.clamp(0, 1),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.primary, AppColors.crimson, AppColors.violet]),
              ),
            ),
          ),
        ),
      );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.selected, required this.onTap, this.dark = false});
  final String label;
  final bool selected;
  final bool dark;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? (dark ? AppColors.purple : AppColors.violet) : const Color(0xFFF0ECF4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (selected && !dark) const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.check, size: 14, color: Colors.white)),
            Text(label,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.textPrimary)),
          ]),
        ),
      );
}

class _SelectChip extends StatelessWidget {
  const _SelectChip({super.key, required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.surfaceTint : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? AppColors.violet : AppColors.divider, width: selected ? 2 : 1),
          ),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      );
}

class _InterestCard extends StatelessWidget {
  const _InterestCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
    this.isNew = false,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool selected;
  final bool isNew;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? color.withOpacity(.6) : AppColors.divider, width: 2),
          ),
          child: Row(children: [
            CircleAvatar(radius: 20, backgroundColor: color, child: Icon(icon, color: Colors.white, size: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  if (isNew) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFFFE4EC), borderRadius: BorderRadius.circular(6)),
                      child: const Text('NEW', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.crimson)),
                    ),
                  ],
                ]),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ]),
            ),
            Icon(selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected ? color : AppColors.divider),
          ]),
        ),
      );
}
