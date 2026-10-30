enum Gender { male, female }

enum Interest { dating, networking, marriage }

class ProfileDraft {
  const ProfileDraft({
    this.name = '',
    this.dateOfBirth,
    this.gender,
    this.interestedIn,
    this.city = 'Indore',
    this.interests = const {Interest.dating},
    this.networkingFields = const {'Software & Tech'},
    this.photoPath,
  });

  final String name;
  final DateTime? dateOfBirth;
  final Gender? gender;
  final Gender? interestedIn;
  final String city;
  final Set<Interest> interests;
  final Set<String> networkingFields;
  final String? photoPath;

  ProfileDraft copyWith({
    String? name,
    DateTime? dateOfBirth,
    Gender? gender,
    Gender? interestedIn,
    String? city,
    Set<Interest>? interests,
    Set<String>? networkingFields,
    String? photoPath,
  }) =>
      ProfileDraft(
        name: name ?? this.name,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        gender: gender ?? this.gender,
        interestedIn: interestedIn ?? this.interestedIn,
        city: city ?? this.city,
        interests: interests ?? this.interests,
        networkingFields: networkingFields ?? this.networkingFields,
        photoPath: photoPath ?? this.photoPath,
      );
}

/// Pure validation, shared with tests. Returns field -> error message.
abstract final class ProfileValidator {
  static int ageOn(DateTime dob, DateTime today) {
    var age = today.year - dob.year;
    if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) age--;
    return age;
  }

  static Map<String, String> validate(ProfileDraft p, {DateTime? today}) {
    final now = today ?? DateTime.now();
    final e = <String, String>{};
    final name = p.name.trim();
    if (name.isEmpty) {
      e['name'] = 'Name is required';
    } else if (name.length < 2 || name.length > 50) {
      e['name'] = 'Name must be 2–50 characters';
    }
    if (p.dateOfBirth == null) {
      e['dob'] = 'Date of birth is required';
    } else if (ageOn(p.dateOfBirth!, now) < 18) {
      e['dob'] = 'You must be 18 or older to use SparkDate';
    }
    if (p.gender == null) e['gender'] = 'Please select your gender';
    if (p.interestedIn == null) e['interestedIn'] = 'Please select who you want to meet';
    if (p.photoPath == null) e['photo'] = 'Add a profile photo';
    if (p.city.trim().isEmpty) e['city'] = 'Select a city';
    if (p.interests.isEmpty) e['interests'] = 'Pick at least one interest';
    if (p.interests.contains(Interest.networking) && p.networkingFields.isEmpty) {
      e['fields'] = 'Pick at least one networking field';
    }
    return e;
  }

  static double completion(ProfileDraft p) {
    const total = 7;
    var done = 0;
    if (p.name.trim().length >= 2) done++;
    if (p.dateOfBirth != null) done++;
    if (p.gender != null) done++;
    if (p.interestedIn != null) done++;
    if (p.photoPath != null) done++;
    if (p.city.isNotEmpty) done++;
    if (p.interests.isNotEmpty) done++;
    return done / total;
  }
}

/// DTOs matching docs/api/AUTH_PROFILE_MEDIA.md.
class ProfilePhoto {
  const ProfilePhoto({required this.key, required this.order, this.url});
  final String key;
  final int order;

  /// Short-lived signed URL (15 min). Never persist; cache images by [key].
  final String? url;

  factory ProfilePhoto.fromJson(Map<String, dynamic> j) =>
      ProfilePhoto(key: j['key'] as String, order: (j['order'] as num?)?.toInt() ?? 0, url: j['url'] as String?);
}

class ProfileView {
  const ProfileView({
    required this.id,
    required this.role,
    required this.profileCompleted,
    required this.verificationStatus,
    this.phone,
    this.email,
    this.fullName,
    this.gender,
    this.interestedIn,
    this.dob,
    this.bio,
    this.city,
    this.interests = const [],
    this.photos = const [],
  });

  final String id;
  final String? phone;
  final String? email;
  final String role;
  final bool profileCompleted;
  final String verificationStatus;
  final String? fullName;
  final Gender? gender;
  final Gender? interestedIn;
  final DateTime? dob;
  final String? bio;
  final String? city;
  final List<String> interests;
  final List<ProfilePhoto> photos;

  static Gender? _g(Object? v) => v == null ? null : Gender.values.byName(v as String);

  factory ProfileView.fromJson(Map<String, dynamic> j) {
    final p = (j['profile'] as Map<String, dynamic>?) ?? const {};
    return ProfileView(
      id: j['id'] as String,
      phone: j['phone'] as String?,
      email: j['email'] as String?,
      role: j['role'] as String? ?? 'user',
      profileCompleted: j['profileCompleted'] as bool? ?? false,
      verificationStatus: ((j['verification'] as Map?)?['status'] as String?) ?? 'none',
      fullName: p['fullName'] as String?,
      gender: _g(p['gender']),
      interestedIn: _g(p['interestedIn']),
      dob: p['dob'] == null ? null : DateTime.parse(p['dob'] as String),
      bio: p['bio'] as String?,
      city: p['city'] as String?,
      interests: ((p['interests'] as List?) ?? const []).cast<String>(),
      photos: ((p['photos'] as List?) ?? const [])
          .map((e) => ProfilePhoto.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order)),
    );
  }
}

/// PUT /profile/me body.
Map<String, dynamic> completeProfileBody(ProfileDraft d, List<String> photoKeys) => {
      'fullName': d.name.trim(),
      'gender': d.gender!.name,
      'interestedIn': d.interestedIn!.name,
      'dob': d.dateOfBirth!.toIso8601String().substring(0, 10),
      'city': d.city,
      'interests': [
        ...d.interests.map((i) => i.name),
        if (d.interests.contains(Interest.networking)) ...d.networkingFields,
      ].take(10).toList(),
      'photos': photoKeys,
    };
