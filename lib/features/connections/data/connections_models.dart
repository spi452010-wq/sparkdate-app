enum LikeTab { youLiked, likedYou, mutual }

/// A person met at a live event (provisional shape: GET /connections).
class Connection {
  const Connection({
    required this.userId,
    required this.name,
    required this.age,
    required this.city,
    this.bio = '',
    this.interests = const [],
    this.photoUrl,
    this.eventTitle,
    this.youLiked = false,
    this.likedYou = false,
    this.saved = false,
    this.lastMessage,
    this.unread = 0,
  });
  final String userId;
  final String name;
  final int age;
  final String city;
  final String bio;
  final List<String> interests;
  final String? photoUrl;
  final String? eventTitle;
  final bool youLiked;
  final bool likedYou;
  final bool saved;
  final String? lastMessage;
  final int unread;
  bool get mutual => youLiked && likedYou;

  Connection copyWith({bool? youLiked, bool? saved, String? lastMessage, int? unread}) => Connection(
      userId: userId,
      name: name,
      age: age,
      city: city,
      bio: bio,
      interests: interests,
      photoUrl: photoUrl,
      eventTitle: eventTitle,
      youLiked: youLiked ?? this.youLiked,
      likedYou: likedYou,
      saved: saved ?? this.saved,
      lastMessage: lastMessage ?? this.lastMessage,
      unread: unread ?? this.unread);

  factory Connection.fromJson(Map<String, dynamic> j) => Connection(
        userId: j['userId'] as String,
        name: j['name'] as String,
        age: (j['age'] as num).toInt(),
        city: j['city'] as String? ?? '',
        bio: j['bio'] as String? ?? '',
        interests: ((j['interests'] as List?) ?? const []).cast<String>(),
        photoUrl: j['photoUrl'] as String?,
        eventTitle: j['eventTitle'] as String?,
        youLiked: j['youLiked'] as bool? ?? false,
        likedYou: j['likedYou'] as bool? ?? false,
        saved: j['saved'] as bool? ?? false,
        lastMessage: j['lastMessage'] as String?,
        unread: (j['unread'] as num?)?.toInt() ?? 0,
      );
}

class ChatMessage {
  const ChatMessage({required this.id, required this.fromMe, required this.text, required this.at});
  final String id;
  final bool fromMe;
  final String text;
  final DateTime at;
  factory ChatMessage.fromJson(Map<String, dynamic> j, String myId) => ChatMessage(
      id: j['id'] as String,
      fromMe: j['senderId'] == myId,
      text: j['text'] as String,
      at: DateTime.parse(j['createdAt'] as String));
}

/// GET /notifications item `{id, type, title, body, data, read, createdAt}`.
enum NotificationType { bookingConfirmed, eventReminder, eventCancelled, refundProcessed, refundRejected, chatPassExpiring, other }

NotificationType notificationTypeFrom(String? s) => switch (s) {
      'booking_confirmed' => NotificationType.bookingConfirmed,
      'event_reminder' => NotificationType.eventReminder,
      'event_cancelled' => NotificationType.eventCancelled,
      'refund_processed' => NotificationType.refundProcessed,
      'refund_rejected' => NotificationType.refundRejected,
      'chat_pass_expiring' => NotificationType.chatPassExpiring,
      _ => NotificationType.other,
    };

class AppNotification {
  const AppNotification(
      {required this.id,
      required this.title,
      required this.body,
      required this.at,
      this.read = false,
      this.type = NotificationType.other,
      this.data = const {}});
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime at;
  final bool read;

  /// e.g. `data.eventId` / `data.bookingId` for deep links.
  String? get eventId => data['eventId'] as String?;

  AppNotification markedRead() => AppNotification(id: id, title: title, body: body, at: at, read: true, type: type, data: data);

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
      id: j['id'] as String,
      type: notificationTypeFrom(j['type'] as String?),
      title: j['title'] as String,
      body: j['body'] as String? ?? '',
      data: (j['data'] as Map?)?.cast<String, dynamic>() ?? const {},
      at: DateTime.parse(j['createdAt'] as String),
      read: j['read'] as bool? ?? false);
}
