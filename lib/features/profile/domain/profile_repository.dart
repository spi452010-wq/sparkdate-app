import 'profile.dart';

abstract interface class ProfileRepository {
  /// POST /media/photos (multipart, field `file`) -> `{ key }`.
  Future<String> uploadPhoto(String path);

  /// Uploads the photo, then PUT /profile/me with the key.
  Future<ProfileView> saveProfile(ProfileDraft draft);

  Future<ProfileView> getMe();
}
