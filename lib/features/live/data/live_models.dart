class LiveMatch {
  const LiveMatch({
    required this.matchId,
    required this.partnerId,
    required this.name,
    required this.age,
    required this.city,
    required this.round,
    required this.roomUrl,
    required this.roomToken,
    required this.roundEndsAt,
    this.bio = '',
    this.interests = const [],
    this.photoUrl,
  });

  final String matchId;
  final String partnerId;
  final String name;
  final int age;
  final String city;
  final int round;
  final String bio;
  final List<String> interests;
  final String? photoUrl;

  /// LiveKit room `evt_{eventId}_r{n}_{pairId}` URL and pair-scoped token.
  final String roomUrl;
  final String roomToken;

  /// Server-authoritative end time — countdowns render from this (ARCHITECTURE §6.4).
  final DateTime roundEndsAt;

  factory LiveMatch.fromJson(Map<String, dynamic> j) => LiveMatch(
        matchId: j['matchId'] as String,
        partnerId: j['partner']['id'] as String,
        name: j['partner']['name'] as String,
        age: (j['partner']['age'] as num).toInt(),
        city: j['partner']['city'] as String? ?? '',
        bio: j['partner']['bio'] as String? ?? '',
        interests: ((j['partner']['interests'] as List?) ?? const []).cast<String>(),
        photoUrl: j['partner']['photoUrl'] as String?,
        round: (j['round'] as num).toInt(),
        roomUrl: j['livekit']['url'] as String,
        roomToken: j['livekit']['token'] as String,
        roundEndsAt: DateTime.parse(j['endsAt'] as String),
      );
}

/// Socket events coming from the live module.
sealed class LiveUpdate {
  const LiveUpdate();
}

class QueueUpdate extends LiveUpdate {
  const QueueUpdate({required this.waiting, required this.attempt, required this.maxAttempts, this.eventNo});
  final int waiting;
  final int attempt;
  final int maxAttempts;
  final String? eventNo;
}

class MatchFoundUpdate extends LiveUpdate {
  const MatchFoundUpdate(this.match);
  final LiveMatch match;
}

class PartnerLeftUpdate extends LiveUpdate {
  const PartnerLeftUpdate();
}

class RoundEndedUpdate extends LiveUpdate {
  const RoundEndedUpdate();
}

class EventEndedUpdate extends LiveUpdate {
  const EventEndedUpdate({required this.completedDates});
  final int completedDates;
}

enum Decision { like, save, pass }

/// mutual = both liked/saved -> Connection created; otherwise waiting for the other side.
class DecisionResult {
  const DecisionResult({required this.mutual, this.connectionId});
  final bool mutual;
  final String? connectionId;
}
