
import '../data/profile_models.dart';
import '../data/profile_repository.dart';

/// In-memory mock returning the same JSON shapes as the real API.
class MockProfileRepository implements ProfileRepository {
  MockProfileRepository({this.latency = const Duration(milliseconds: 500)});
  final Duration latency;
  Map<String, dynamic>? _saved;
  int _n = 0;

  Future<void> _delay() => latency == Duration.zero ? Future.value() : Future.delayed(latency);

  @override
  Future<String> uploadPhoto(String path) async {
    await _delay();
    return 'photos/mock_user/${++_n}.webp';
  }

  @override
  Future<ProfileView> saveProfile(ProfileDraft d) async {
    final key = await uploadPhoto(d.photoPath!);
    final body = completeProfileBody(d, [key]);
    // Idempotent in the mock: re-submit overwrites.
    _saved = {
      'id': 'mock_user',
      'role': 'user',
      'profileCompleted': true,
      'verification': {'status': 'none'},
      'profile': {
        ...body,
        'photos': [
          {'key': key, 'order': 0, 'url': 'file://${d.photoPath}'},
        ],
      },
    };
    return ProfileView.fromJson(_saved!);
  }

  @override
  Future<ProfileView> getMe() async {
    await _delay();
    return ProfileView.fromJson(_saved ??
        {'id': 'mock_user', 'role': 'user', 'profileCompleted': false, 'verification': {'status': 'none'}});
  }

  @override
  Future<ProfileView> updateProfile(Map<String, dynamic> changes) async {
    await _delay();
    _saved ??= {
      'id': 'mock_user',
      'role': 'user',
      'profileCompleted': true,
      'verification': {'status': verification},
      'profile': <String, dynamic>{'fullName': 'You', 'city': 'Mumbai', 'interests': <String>[]},
    };
    (_saved!['profile'] as Map<String, dynamic>).addAll(changes);
    return ProfileView.fromJson(_saved!);
  }

  String verification = 'none';

  @override
  Future<String> submitSelfie(String path) async {
    await _delay();
    verification = 'pending';
    if (_saved != null) _saved!['verification'] = {'status': verification};
    return verification;
  }
}
