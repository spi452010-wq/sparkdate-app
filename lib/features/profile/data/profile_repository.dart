import 'profile_models.dart';

abstract interface class ProfileRepository {
  /// POST /media/photos (multipart, field `file`) -> `{ key }`.
  Future<String> uploadPhoto(String path);

  /// Uploads the photo, then PUT /profile/me with the key.
  Future<ProfileView> saveProfile(ProfileDraft draft);

  Future<ProfileView> getMe();

  /// POST /media/selfie (multipart) -> `{ key }`, then POST /profile/me/verification `{ selfieKey }`
  /// -> 202 `{ status: "pending" }`. Returns the verification status.
  Future<String> submitSelfie(String path);
}
