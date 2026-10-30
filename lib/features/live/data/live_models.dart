// Sprint 3 live-session contract (sparkdate-api docs/SPRINT3_LIVE_SESSION.md §2).

Map<String, dynamic> _map(Object? o) => o is Map ? Map<String, dynamic>.from(o) : <String, dynamic>{};
DateTime _time(Object? o) => o is num ? DateTime.fromMillisecondsSinceEpoch(o.toInt(), isUtc: true) : DateTime.parse(o as String);
DateTime? _timeOrNull(Object? o) => o == null ? null : _time(o);

/// Partner card as sent in `match:found` / `connection:mutual`.
class LivePartner {
  const LivePartner({required this.id, required this.fullName, this.age = 0, this.city = '', this.photoUrl, this.interests = const [], this.bio = ''});
  final String id;
  final String fullName;
  final int age;
  final String city;
  final String? photoUrl;
  final List<String> interests;
  final String bio;

  factory LivePartner.fromJson(Map<String, dynamic> j) => LivePartner(
        id: j['id'] as String,
        fullName: j['fullName'] as String? ?? '',
        age: (j['age'] as num?)?.toInt() ?? 0,
        city: j['city'] as String? ?? '',
        photoUrl: j['photoUrl'] as String?,
        interests: ((j['interests'] as List?) ?? const []).cast<String>(),
        bio: j['bio'] as String? ?? '',
      );
}

/// One date in a round: `match:found {dateId, round, partner, livekit:{url, room, token}, startsAt, endsAt}`.
class LiveMatch {
  const LiveMatch({
    required this.dateId,
    required this.round,
    required this.partner,
    required this.livekitUrl,
    required this.livekitRoom,
    required this.livekitToken,
    required this.startsAt,
    required this.endsAt,
  });

  final String dateId;
  final int round;
  final LivePartner partner;

  /// Per-date LiveKit room `evt_{e}_r{n}_{dateId}`; the token only grants that room.
  final String livekitUrl;
  final String livekitRoom;
  final String livekitToken;

  /// Server time. Countdowns use these minus the server-time offset, never a local timer.
  final DateTime startsAt;
  final DateTime endsAt;

  /// Not in the socket contract; kept for the intro card (empty from the server).

  String get partnerId => partner.id;
  String get name => partner.fullName;
  int get age => partner.age;
  String get city => partner.city;
  String? get photoUrl => partner.photoUrl;
  List<String> get interests => partner.interests;
  String get bio => partner.bio;

  LiveMatch copyWith({DateTime? endsAt}) => LiveMatch(
      dateId: dateId,
      round: round,
      partner: partner,
      livekitUrl: livekitUrl,
      livekitRoom: livekitRoom,
      livekitToken: livekitToken,
      startsAt: startsAt,
      endsAt: endsAt ?? this.endsAt);

  factory LiveMatch.fromJson(Map<String, dynamic> j) {
    final lk = _map(j['livekit']);
    return LiveMatch(
      dateId: j['dateId'] as String,
      round: (j['round'] as num).toInt(),
      partner: LivePartner.fromJson(_map(j['partner'])),
      livekitUrl: lk['url'] as String,
      livekitRoom: lk['room'] as String? ?? '',
      livekitToken: lk['token'] as String,
      startsAt: _time(j['startsAt']),
      endsAt: _time(j['endsAt']),
    );
  }
}

/// Everything the live session can tell the controller.
sealed class LiveUpdate {
  const LiveUpdate();

  /// Maps a server -> client socket event to an update (null = unknown event).
  static LiveUpdate? fromSocket(String event, Object? data) {
    final j = _map(data);
    return switch (event) {
      'lobby:state' => LobbyStateUpdate(
          eventId: j['eventId'] as String? ?? '',
          round: (j['round'] as num?)?.toInt() ?? 0,
          status: j['status'] as String? ?? '',
          waiting: (j['waiting'] as num?)?.toInt() ?? 0,
          nextRoundAt: _timeOrNull(j['nextRoundAt'])),
      'match:found' => MatchFoundUpdate(LiveMatch.fromJson(j)),
      'round:started' => RoundStartedUpdate(dateId: j['dateId'] as String, endsAt: _time(j['endsAt'])),
      'round:ended' => RoundEndedUpdate(dateId: j['dateId'] as String, decisionDeadline: _time(j['decisionDeadline'])),
      'partner:left' => PartnerLeftUpdate(dateId: j['dateId'] as String, reason: j['reason'] as String? ?? 'left'),
      'connection:mutual' => ConnectionMutualUpdate(connectionId: j['connectionId'] as String, partner: LivePartner.fromJson(_map(j['partner']))),
      'date:spark' => SparkReceivedUpdate(dateId: j['dateId'] as String? ?? ''),
      'no:match' => NoMatchUpdate(round: (j['round'] as num?)?.toInt() ?? 0),
      'event:ended' => EventEndedUpdate(eventId: j['eventId'] as String? ?? '', datesCompleted: (j['datesCompleted'] as num?)?.toInt() ?? 0),
      _ => null,
    };
  }
}

/// Partner sent a spark (`date:spark {dateId}` from the server).
class SparkReceivedUpdate extends LiveUpdate {
  const SparkReceivedUpdate({required this.dateId});
  final String dateId;
}

class LobbyStateUpdate extends LiveUpdate {
  const LobbyStateUpdate({required this.eventId, required this.round, required this.status, required this.waiting, this.nextRoundAt});
  final String eventId;
  final int round;
  final String status;
  final int waiting;
  final DateTime? nextRoundAt;
}

class MatchFoundUpdate extends LiveUpdate {
  const MatchFoundUpdate(this.match);
  final LiveMatch match;
}

class RoundStartedUpdate extends LiveUpdate {
  const RoundStartedUpdate({required this.dateId, required this.endsAt});
  final String dateId;
  final DateTime endsAt;
}

class RoundEndedUpdate extends LiveUpdate {
  const RoundEndedUpdate({required this.dateId, required this.decisionDeadline});
  final String dateId;
  final DateTime decisionDeadline;
}

class PartnerLeftUpdate extends LiveUpdate {
  const PartnerLeftUpdate({required this.dateId, required this.reason});
  final String dateId;

  /// "disconnect" (grace expired) | "left".
  final String reason;
}

class ConnectionMutualUpdate extends LiveUpdate {
  const ConnectionMutualUpdate({required this.connectionId, required this.partner});
  final String connectionId;
  final LivePartner partner;
}

class NoMatchUpdate extends LiveUpdate {
  const NoMatchUpdate({required this.round});
  final int round;
}

class EventEndedUpdate extends LiveUpdate {
  const EventEndedUpdate({required this.eventId, required this.datesCompleted});
  final String eventId;
  final int datesCompleted;
}

/// Our socket dropped; the server holds our slot until [graceEndsAt] (20 s).
class ReconnectingUpdate extends LiveUpdate {
  const ReconnectingUpdate({required this.graceEndsAt});
  final DateTime graceEndsAt;
}

/// Back within grace; `event:join` was re-sent and the server resends `match:found` with a fresh token.
class ReconnectedUpdate extends LiveUpdate {
  const ReconnectedUpdate();
}

/// Grace expired: the server has ended our date as early_disconnect.
class GraceExpiredUpdate extends LiveUpdate {
  const GraceExpiredUpdate();
}

/// `event:join` was refused (e.g. no confirmed booking).
class JoinRejectedUpdate extends LiveUpdate {
  const JoinRejectedUpdate(this.error);
  final String error;
}

enum Decision { like, save, pass }

/// A client -> server ack came back `{ok: false, error}`.
class LiveAckException implements Exception {
  const LiveAckException(this.error);
  final String error;

  /// `date:*` acks for a date that no longer exists / already ended (or a malformed/stale id).
  bool get staleDate => error == 'DATE_NOT_FOUND' || error == 'DATE_NOT_ACTIVE' || error == 'VALIDATION_ERROR';
  @override
  String toString() => error;
}
