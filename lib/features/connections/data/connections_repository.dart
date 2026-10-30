import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'connections_models.dart';

abstract interface class ConnectionsRepository {
  Future<List<Connection>> list();
  Future<Connection> get(String userId);
  Future<Connection> toggleSaved(String userId);
  Future<bool> hasChatPass();
  Future<List<ChatMessage>> messages(String userId);

  /// Throws [ApiErrorCode.chatPassRequired] without an active Chat Pass.
  Future<ChatMessage> send(String userId, String text);
  Future<List<AppNotification>> notifications();
}

class MockConnectionsRepository implements ConnectionsRepository {
  MockConnectionsRepository({this.chatPass = false});
  bool chatPass;
  final _people = <String, Connection>{
    for (final c in [
      const Connection(
          userId: 'u_ananya',
          name: 'Ananya',
          age: 26,
          city: 'Mumbai',
          bio: 'Coffee, books and long walks.',
          interests: ['Travel', 'Music'],
          eventTitle: 'Friday Night Speed Dating',
          youLiked: true,
          likedYou: true,
          lastMessage: 'That was fun! 😊',
          unread: 1),
      const Connection(
          userId: 'u_rohan',
          name: 'Rohan',
          age: 28,
          city: 'Pune',
          bio: 'Product designer.',
          interests: ['Design'],
          eventTitle: 'Founders Mixer',
          youLiked: true),
      const Connection(
          userId: 'u_meera',
          name: 'Meera',
          age: 25,
          city: 'Mumbai',
          bio: 'Dancer & foodie.',
          interests: ['Dance', 'Food'],
          eventTitle: 'Friday Night Speed Dating',
          likedYou: true,
          saved: true),
      const Connection(
          userId: 'u_kabir',
          name: 'Kabir',
          age: 29,
          city: 'Delhi',
          interests: ['Fitness'],
          eventTitle: 'Weekend Mixer',
          saved: true),
    ])
      c.userId: c
  };
  final _msgs = <String, List<ChatMessage>>{
    'u_ananya': [ChatMessage(id: 'm1', fromMe: false, text: 'That was fun! 😊', at: DateTime(2026, 10, 29, 21))],
  };

  Connection _get(String id) => _people[id] ?? (throw const ApiException(ApiErrorCode.unknown));

  @override
  Future<List<Connection>> list() async => _people.values.toList();
  @override
  Future<Connection> get(String userId) async => _get(userId);
  @override
  Future<Connection> toggleSaved(String userId) async {
    final c = _get(userId);
    return _people[userId] = c.copyWith(saved: !c.saved);
  }

  @override
  Future<bool> hasChatPass() async => chatPass;
  @override
  Future<List<ChatMessage>> messages(String userId) async => List.of(_msgs[userId] ?? const []);
  @override
  Future<ChatMessage> send(String userId, String text) async {
    if (!chatPass) throw const ApiException(ApiErrorCode.chatPassRequired);
    final m = ChatMessage(id: 'm${DateTime.now().microsecondsSinceEpoch}', fromMe: true, text: text, at: DateTime.now());
    (_msgs[userId] ??= []).add(m);
    _people[userId] = _get(userId).copyWith(lastMessage: text, unread: 0);
    return m;
  }

  @override
  Future<List<AppNotification>> notifications() async => [
        AppNotification(
            id: 'n1', title: "It's a match! 🎉", body: 'You and Ananya liked each other.', at: DateTime(2026, 10, 29, 22)),
        AppNotification(
            id: 'n2',
            title: 'Event tomorrow',
            body: 'Friday Night Speed Dating starts at 8 PM.',
            at: DateTime(2026, 10, 29, 9),
            read: true),
      ];
}

/// Provisional endpoints (not yet in the API contract): /connections, /chats, /notifications.
class RemoteConnectionsRepository implements ConnectionsRepository {
  RemoteConnectionsRepository(this._dio, this._myId);
  final Dio _dio;
  final String Function() _myId;

  Future<T> _run<T>(Future<T> Function() f) async {
    try {
      return await f();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<List<Connection>> list() => _run(() async {
        final r = await _dio.get<Map<String, dynamic>>('/connections');
        return (r.data!['items'] as List).map((e) => Connection.fromJson(e as Map<String, dynamic>)).toList();
      });
  @override
  Future<Connection> get(String userId) =>
      _run(() async => Connection.fromJson((await _dio.get<Map<String, dynamic>>('/connections/$userId')).data!));
  @override
  Future<Connection> toggleSaved(String userId) =>
      _run(() async => Connection.fromJson((await _dio.post<Map<String, dynamic>>('/connections/$userId/save')).data!));
  @override
  Future<bool> hasChatPass() => _run(
      () async => ((await _dio.get<Map<String, dynamic>>('/subscriptions/me')).data!['chatPass']?['active'] as bool?) ?? false);
  @override
  Future<List<ChatMessage>> messages(String userId) => _run(() async {
        final r = await _dio.get<Map<String, dynamic>>('/chats/$userId/messages');
        return (r.data!['items'] as List).map((e) => ChatMessage.fromJson(e as Map<String, dynamic>, _myId())).toList();
      });
  @override
  Future<ChatMessage> send(String userId, String text) => _run(() async => ChatMessage.fromJson(
      (await _dio.post<Map<String, dynamic>>('/chats/$userId/messages', data: {'text': text})).data!, _myId()));
  @override
  Future<List<AppNotification>> notifications() => _run(() async {
        final r = await _dio.get<Map<String, dynamic>>('/notifications');
        return (r.data!['items'] as List).map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList();
      });
}
