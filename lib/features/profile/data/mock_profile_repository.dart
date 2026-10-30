import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/profile.dart';
import '../domain/profile_repository.dart';
import 'remote_profile_repository.dart';

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
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  if (useMockApi) return MockProfileRepository();
  return RemoteProfileRepository(ref.watch(dioProvider));
});
