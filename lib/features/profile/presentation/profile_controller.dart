import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';

import '../data/mock_profile_repository.dart';
import '../domain/profile.dart';

class ProfileFormState {
  const ProfileFormState({this.draft = const ProfileDraft(), this.errors = const {}, this.saving = false, this.apiError});
  final ApiException? apiError;
  final ProfileDraft draft;
  final Map<String, String> errors;
  final bool saving;
}

class ProfileController extends Notifier<ProfileFormState> {
  @override
  ProfileFormState build() => const ProfileFormState();

  void update(ProfileDraft d) {
    // Keep entered data; clear errors that are now fixed.
    final still = Map.of(state.errors)..removeWhere((k, _) => !ProfileValidator.validate(d).containsKey(k));
    state = ProfileFormState(draft: d, errors: still, saving: state.saving);
  }

  Future<bool> submit() async {
    if (state.saving) return false;
    final errors = ProfileValidator.validate(state.draft);
    if (errors.isNotEmpty) {
      state = ProfileFormState(draft: state.draft, errors: errors);
      return false;
    }
    state = ProfileFormState(draft: state.draft, saving: true);
    try {
      await ref.read(profileRepositoryProvider).saveProfile(state.draft);
      state = ProfileFormState(draft: state.draft);
      return true;
    } on ApiException catch (e) {
      state = ProfileFormState(draft: state.draft, apiError: e);
      return false;
    } finally {
      if (state.saving) {
        state = ProfileFormState(draft: state.draft);
      }
    }
  }
}

final profileControllerProvider = NotifierProvider<ProfileController, ProfileFormState>(ProfileController.new);
