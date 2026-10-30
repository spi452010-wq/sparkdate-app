import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/ui.dart';
import '../controllers/my_profile_controller.dart';
import '../data/profile_models.dart';

int? _age(DateTime? dob) => dob == null ? null : (DateTime.now().difference(dob).inDays / 365.25).floor();
String? _photo(ProfileView p) => p.photos.isEmpty ? null : p.photos.first.url;

/// Profile_page — the Profile tab.
class ProfilePageView extends GetView<MyProfileController> {
  const ProfilePageView({super.key});

  Widget _item(IconData i, String label, VoidCallback onTap, {Key? key, Color? color}) => ListTile(
        key: key,
        leading: Icon(i, color: color ?? AppColors.violet),
        title: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.w700))),
        bottomNavigationBar: const AppBottomNav(current: NavTab.profile),
        body: Obx(() {
          final p = controller.me.value;
          if (p == null) return const Center(child: CircularProgressIndicator());
          final age = _age(p.dob);
          return ListView(padding: const EdgeInsets.all(16), children: [
            AppCard(
              onTap: () => Get.toNamed(Routes.profileDetails),
              child: Row(children: [
                Avatar(p.fullName ?? '', url: _photo(p), size: 64),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text([p.fullName ?? 'You', if (age != null) '$age'].join(', '),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    Text(p.city ?? '', style: const TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Pill(p.verificationStatus == 'verified' ? 'VERIFIED' : 'VERIFICATION: ${p.verificationStatus.toUpperCase()}',
                        color: p.verificationStatus == 'verified' ? AppColors.success : AppColors.violet),
                  ]),
                ),
                const Icon(Icons.chevron_right),
              ]),
            ),
            const SizedBox(height: 16),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(children: [
                _item(Icons.edit_outlined, 'Edit Profile', () => Get.toNamed(Routes.editProfile), key: const Key('open_edit')),
                _item(Icons.favorite_border, 'Likes', () => Get.toNamed(Routes.likes)),
                _item(Icons.bookmark_outline, 'Saved Connections', () => Get.toNamed(Routes.saved)),
                _item(Icons.event_outlined, 'My Events', () => Get.offAllNamed(Routes.events)),
                _item(Icons.workspace_premium_outlined, 'Chat Pass', () => Get.toNamed(Routes.chatSubscription)),
                _item(Icons.notifications_none, 'Notifications', () => Get.toNamed(Routes.notifications)),
              ]),
            ),
            const SizedBox(height: 16),
            AppCard(
              padding: EdgeInsets.zero,
              child: _item(Icons.logout, 'Log out', controller.logout, color: AppColors.error, key: const Key('logout')),
            ),
          ]);
        }),
      );
}

/// Profile — full read-only details.
class ProfileDetailsView extends GetView<MyProfileController> {
  const ProfileDetailsView({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: simpleAppBar('My Profile', actions: [
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => Get.toNamed(Routes.editProfile)),
        ]),
        body: Obx(() {
          final p = controller.me.value;
          if (p == null) return const Center(child: CircularProgressIndicator());
          return ListView(padding: const EdgeInsets.all(20), children: [
            Center(child: Avatar(p.fullName ?? '', url: _photo(p), size: 120)),
            const SizedBox(height: 16),
            AppCard(
              child: Column(children: [
                KeyValueRow('Name', p.fullName ?? '—'),
                KeyValueRow('Age', '${_age(p.dob) ?? '—'}'),
                KeyValueRow('Gender', p.gender?.name ?? '—'),
                KeyValueRow('Interested in', p.interestedIn?.name ?? '—'),
                KeyValueRow('City', p.city ?? '—'),
                KeyValueRow('Phone', p.phone ?? '—'),
              ]),
            ),
            if ((p.bio ?? '').isNotEmpty) ...[const SizedBox(height: 16), const SectionHeader('About'), Text(p.bio!)],
            if (p.interests.isNotEmpty) ...[
              const SizedBox(height: 16),
              const SectionHeader('Interests'),
              Wrap(spacing: 8, runSpacing: 8, children: p.interests.map((i) => Pill(i)).toList()),
            ],
          ]);
        }),
      );
}

/// Edit_Profile — PATCH /profile/me with changed fields only.
class EditProfileView extends GetView<MyProfileController> {
  const EditProfileView({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: simpleAppBar('Edit Profile'),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          TextField(
              key: const Key('edit_name'),
              controller: controller.name,
              decoration: const InputDecoration(labelText: 'Full name')),
          const SizedBox(height: 12),
          TextField(
              key: const Key('edit_city'), controller: controller.city, decoration: const InputDecoration(labelText: 'City')),
          const SizedBox(height: 12),
          TextField(
              key: const Key('edit_bio'),
              controller: controller.bio,
              maxLines: 4,
              maxLength: 300,
              decoration: const InputDecoration(labelText: 'Bio')),
          const SizedBox(height: 24),
          Obx(() => GradientButton(
              key: const Key('edit_save'),
              label: controller.saving.value ? 'Saving…' : 'Save Changes',
              onPressed: controller.saving.value ? null : controller.save)),
        ]),
      );
}
