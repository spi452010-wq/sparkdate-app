import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/ui.dart';
import '../../billing/data/payments_repository.dart';
import '../../billing/services/billing_service.dart';
import '../../live/data/live_models.dart';
import '../data/connections_models.dart';
import '../data/connections_repository.dart';

/// Likes (3 tabs), Saved and Chat history all read the same connection list.
class ConnectionsController extends GetxController {
  final _repo = Get.find<ConnectionsRepository>();
  final all = <Connection>[].obs;
  final loading = true.obs;
  final tab = LikeTab.youLiked.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    try {
      all.assignAll(await _repo.list());
    } catch (e) {
      showError(e);
    } finally {
      loading.value = false;
    }
  }

  List<Connection> byTab(LikeTab t) => switch (t) {
        LikeTab.youLiked => all.where((c) => c.youLiked && !c.likedYou).toList(),
        LikeTab.likedYou => all.where((c) => c.likedYou && !c.youLiked).toList(),
        LikeTab.mutual => all.where((c) => c.mutual).toList(),
      };
  List<Connection> get saved => all.where((c) => c.saved).toList();
  List<Connection> get chats => all.where((c) => c.mutual).toList();

  Future<void> toggleSaved(String id) async {
    try {
      final c = await _repo.toggleSaved(id);
      final i = all.indexWhere((x) => x.userId == id);
      if (i >= 0) all[i] = c;
    } catch (e) {
      showError(e);
    }
  }
}

/// Connection Profile Detail. Accepts a userId String or a [LiveMatch] (from Mutual Connection).
class ConnectionDetailController extends GetxController {
  final _repo = Get.find<ConnectionsRepository>();
  final connection = Rxn<Connection>();

  @override
  void onInit() {
    super.onInit();
    final a = Get.arguments;
    if (a is LiveMatch) {
      connection.value = Connection(
          userId: a.partnerId,
          name: a.name,
          age: a.age,
          city: a.city,
          bio: a.bio,
          interests: a.interests,
          photoUrl: a.photoUrl,
          youLiked: true,
          likedYou: true);
    }
    final id = a is LiveMatch ? a.partnerId : a as String?;
    if (id != null) _repo.get(id).then((c) => connection.value = c, onError: (_) {});
  }

  Future<void> toggleSaved() async {
    final c = connection.value;
    if (c == null) return;
    try {
      connection.value = await _repo.toggleSaved(c.userId);
    } catch (e) {
      showError(e);
    }
  }

  Future<void> message() async {
    final c = connection.value;
    if (c == null) return;
    final pass = await _repo.hasChatPass();
    Get.toNamed(pass ? Routes.chat : Routes.chatSubscription, arguments: c);
  }
}

class ChatController extends GetxController {
  final _repo = Get.find<ConnectionsRepository>();
  late final Connection peer = Get.arguments as Connection;
  final messages = <ChatMessage>[].obs;
  final input = TextEditingController();
  final sending = false.obs;

  @override
  void onInit() {
    super.onInit();
    _repo.messages(peer.userId).then(messages.assignAll, onError: showError);
  }

  Future<void> send() async {
    final t = input.text.trim();
    if (t.isEmpty || sending.value) return;
    sending.value = true;
    try {
      messages.add(await _repo.send(peer.userId, t));
      input.clear();
    } catch (e) {
      showError(e);
      if (e is ApiException && e.error == ApiErrorCode.chatPassRequired) Get.toNamed(Routes.chatSubscription, arguments: peer);
    } finally {
      sending.value = false;
    }
  }

  @override
  void onClose() {
    input.dispose();
    super.onClose();
  }
}

/// Chat Pass: Play subscription `chat_pass_monthly` → POST /payments/play/verify activates it.
class ChatSubscriptionController extends GetxController {
  final _billing = Get.find<BillingService>();
  final _payments = Get.find<PaymentsRepository>();
  final _api = Get.find<ApiClient>();
  final busy = false.obs;

  Future<void> subscribe() async {
    if (busy.value) return;
    busy.value = true;
    try {
      final p = await _billing.subscribeChatPass(userId: _api.userId.value ?? '');
      await _payments.verifyPlayPurchase(p);
      final repo = Get.find<ConnectionsRepository>();
      if (repo is MockConnectionsRepository) repo.chatPass = true;
      Get.offNamed(Routes.subscriptionSuccess, arguments: Get.arguments);
    } catch (e) {
      showError(e);
    } finally {
      busy.value = false;
    }
  }
}

class NotificationsController extends GetxController {
  final items = <AppNotification>[].obs;
  @override
  void onInit() {
    super.onInit();
    Get.find<ConnectionsRepository>().notifications().then(items.assignAll, onError: showError);
  }
}
