import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/ui.dart';
import '../data/profile_models.dart';
import '../data/profile_repository.dart';

/// Profile tab, Profile details and Edit Profile.
class MyProfileController extends GetxController {
  final _repo = Get.find<ProfileRepository>();
  final me = Rxn<ProfileView>();
  final saving = false.obs;
  final name = TextEditingController();
  final bio = TextEditingController();
  final city = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    try {
      _fill(me.value = await _repo.getMe());
    } catch (e) {
      showError(e);
    }
  }

  void _fill(ProfileView p) {
    name.text = p.fullName ?? '';
    bio.text = p.bio ?? '';
    city.text = p.city ?? '';
  }

  /// Sends only changed fields (PATCH semantics).
  Map<String, dynamic> changes() {
    final p = me.value;
    return {
      if (name.text.trim() != (p?.fullName ?? '')) 'fullName': name.text.trim(),
      if (bio.text.trim() != (p?.bio ?? '')) 'bio': bio.text.trim(),
      if (city.text.trim() != (p?.city ?? '')) 'city': city.text.trim(),
    };
  }

  Future<void> save() async {
    if (name.text.trim().length < 2) return showError(const ApiException(ApiErrorCode.validation));
    final c = changes();
    if (c.isEmpty) return Get.back<void>();
    saving.value = true;
    try {
      _fill(me.value = await _repo.updateProfile(c));
      Get.back<void>();
    } catch (e) {
      showError(e);
    } finally {
      saving.value = false;
    }
  }

  void logout() {
    final api = Get.find<ApiClient>();
    api.accessToken.value = null;
    api.refreshToken.value = null;
    api.userId.value = null;
    Get.offAllNamed(Routes.login);
  }

  @override
  void onClose() {
    name.dispose();
    bio.dispose();
    city.dispose();
    super.onClose();
  }
}
