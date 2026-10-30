import 'package:flutter_test/flutter_test.dart';
import 'package:sparkdate/features/profile/data/profile_models.dart';

void main() {
  final today = DateTime(2026, 10, 30);
  final valid = ProfileDraft(
    name: 'Riya',
    dateOfBirth: DateTime(2000, 1, 1),
    gender: Gender.female,
    interestedIn: Gender.male,
    photoPath: '/tmp/p.jpg',
  );

  test('valid draft has no errors', () {
    expect(ProfileValidator.validate(valid, today: today), isEmpty);
  });

  test('required fields', () {
    final e = ProfileValidator.validate(const ProfileDraft(interests: {}), today: today);
    expect(e.keys, containsAll(['name', 'dob', 'gender', 'interestedIn', 'photo', 'interests']));
  });

  test('18+ boundary', () {
    expect(ProfileValidator.validate(valid.copyWith(dateOfBirth: DateTime(2008, 10, 30)), today: today), isEmpty);
    expect(ProfileValidator.validate(valid.copyWith(dateOfBirth: DateTime(2008, 10, 31)), today: today)['dob'],
        contains('18'));
  });

  test('name length', () {
    expect(ProfileValidator.validate(valid.copyWith(name: 'A'), today: today), contains('name'));
    expect(ProfileValidator.validate(valid.copyWith(name: 'A' * 51), today: today), contains('name'));
  });

  test('networking requires a field', () {
    final d = valid.copyWith(interests: {Interest.networking}, networkingFields: {});
    expect(ProfileValidator.validate(d, today: today), contains('fields'));
  });
}

