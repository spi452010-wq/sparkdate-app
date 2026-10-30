import 'package:flutter_test/flutter_test.dart';
import 'package:sparkdate/features/profile/data/profile_models.dart';

void main() {
  test('PUT body matches API contract field names', () {
    final d = ProfileDraft(
      name: ' Riya ',
      dateOfBirth: DateTime(2000, 5, 9),
      gender: Gender.female,
      interestedIn: Gender.male,
      interests: {Interest.dating},
      photoPath: '/x.jpg',
    );
    final b = completeProfileBody(d, ['photos/u/1.webp']);
    expect(b.keys.toSet(), {'fullName', 'gender', 'interestedIn', 'dob', 'city', 'interests', 'photos'});
    expect(b['fullName'], 'Riya');
    expect(b['dob'], '2000-05-09');
    expect(b['photos'], ['photos/u/1.webp']);
    expect(b['interests'], ['dating']); // networking fields only when networking selected
  });

  test('ProfileView parses photos sorted by order', () {
    final v = ProfileView.fromJson({
      'id': 'u1',
      'role': 'user',
      'profileCompleted': true,
      'verification': {'status': 'pending'},
      'profile': {
        'fullName': 'Riya',
        'gender': 'female',
        'interestedIn': 'male',
        'dob': '2000-05-09',
        'photos': [
          {'key': 'b', 'order': 1, 'url': 'https://x/b'},
          {'key': 'a', 'order': 0, 'url': 'https://x/a'},
        ],
      },
    });
    expect(v.photos.first.key, 'a');
    expect(v.interestedIn, Gender.male);
    expect(v.verificationStatus, 'pending');
  });
}
