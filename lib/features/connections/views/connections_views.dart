import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/ui.dart';
import '../controllers/connections_controllers.dart';
import '../data/connections_models.dart';

class _PersonTile extends StatelessWidget {
  const _PersonTile(this.c, {this.trailing, this.subtitle});
  final Connection c;
  final Widget? trailing;
  final String? subtitle;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AppCard(
          onTap: () => Get.toNamed(Routes.connectionDetail, arguments: c.userId),
          child: Row(children: [
            Avatar(c.name, url: c.photoUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${c.name}, ${c.age}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                Text(subtitle ?? [c.city, if (c.eventTitle != null) c.eventTitle!].join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ]),
            ),
            if (trailing != null) trailing!,
          ]),
        ),
      );
}

Widget _empty(String text) => Center(
    child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary))));

/// Likes — tabs: You Liked • They Liked You • Mutual.
class LikesView extends GetView<ConnectionsController> {
  const LikesView({super.key});
  static const _labels = {LikeTab.youLiked: 'You Liked', LikeTab.likedYou: 'Liked You', LikeTab.mutual: 'Mutual'};
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: simpleAppBar('Likes', actions: [
          IconButton(
              key: const Key('open_saved'), icon: const Icon(Icons.bookmark_outline), onPressed: () => Get.toNamed(Routes.saved)),
        ]),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Obx(() => Row(
                  children: LikeTab.values
                      .map((t) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: ChoiceChip(
                                key: Key('tab_${t.name}'),
                                label: SizedBox(width: double.infinity, child: Text(_labels[t]!, textAlign: TextAlign.center)),
                                selected: controller.tab.value == t,
                                onSelected: (_) => controller.tab.value = t,
                              ),
                            ),
                          ))
                      .toList(),
                )),
          ),
          Expanded(
            child: Obx(() {
              if (controller.loading.value) return const Center(child: CircularProgressIndicator());
              final list = controller.byTab(controller.tab.value);
              if (list.isEmpty) return _empty('No one here yet. Join a live event to meet people!');
              return ListView(
                padding: const EdgeInsets.all(16),
                children: list
                    .map((c) => _PersonTile(c,
                        trailing: c.mutual ? const Pill('MUTUAL', color: AppColors.success) : const Icon(Icons.chevron_right)))
                    .toList(),
              );
            }),
          ),
        ]),
      );
}

class SavedConnectionsView extends GetView<ConnectionsController> {
  const SavedConnectionsView({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: simpleAppBar('Saved Connections'),
        body: Obx(() {
          final list = controller.saved;
          if (controller.loading.value) return const Center(child: CircularProgressIndicator());
          if (list.isEmpty) return _empty('Profiles you save will show up here.');
          return ListView(
            padding: const EdgeInsets.all(16),
            children: list
                .map((c) => _PersonTile(c,
                    trailing: IconButton(
                        key: Key('unsave_${c.userId}'),
                        icon: const Icon(Icons.bookmark, color: AppColors.violet),
                        onPressed: () => controller.toggleSaved(c.userId))))
                .toList(),
          );
        }),
      );
}

class ConnectionDetailView extends GetView<ConnectionDetailController> {
  const ConnectionDetailView({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: simpleAppBar('Profile', actions: [
          Obx(() => IconButton(
                key: const Key('detail_save'),
                icon: Icon(controller.connection.value?.saved == true ? Icons.bookmark : Icons.bookmark_outline),
                onPressed: controller.toggleSaved,
              )),
        ]),
        body: Obx(() {
          final c = controller.connection.value;
          if (c == null) return const Center(child: CircularProgressIndicator());
          return ListView(padding: const EdgeInsets.all(20), children: [
            Center(child: Avatar(c.name, url: c.photoUrl, size: 120)),
            const SizedBox(height: 16),
            Center(child: Text('${c.name}, ${c.age}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800))),
            Center(child: Text(c.city, style: const TextStyle(color: AppColors.textSecondary))),
            if (c.mutual) ...[
              const SizedBox(height: 8),
              const Center(child: Pill('MUTUAL CONNECTION', color: AppColors.success))
            ],
            const SizedBox(height: 20),
            if (c.bio.isNotEmpty) ...[const SectionHeader('About'), Text(c.bio), const SizedBox(height: 16)],
            if (c.interests.isNotEmpty) ...[
              const SectionHeader('Interests'),
              Wrap(spacing: 8, runSpacing: 8, children: c.interests.map((i) => Pill(i)).toList()),
            ],
            if (c.eventTitle != null) ...[const SizedBox(height: 16), KeyValueRow('Met at', c.eventTitle!)],
            const SizedBox(height: 24),
            if (c.mutual) GradientButton(key: const Key('detail_message'), label: 'Message', onPressed: controller.message),
          ]);
        }),
      );
}

/// Chat history (mutual connections only).
class ChatsView extends GetView<ConnectionsController> {
  const ChatsView({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Chats', style: TextStyle(fontWeight: FontWeight.w700)), actions: [
          IconButton(
              key: const Key('open_likes'), icon: const Icon(Icons.favorite_border), onPressed: () => Get.toNamed(Routes.likes)),
        ]),
        bottomNavigationBar: const AppBottomNav(current: NavTab.chat),
        body: Obx(() {
          if (controller.loading.value) return const Center(child: CircularProgressIndicator());
          final list = controller.chats;
          if (list.isEmpty) return _empty('Mutual connections appear here. Like someone after a date to start chatting.');
          return ListView(
            padding: const EdgeInsets.all(16),
            children: list
                .map((c) => GestureDetector(
                      onTap: () => Get.toNamed(Routes.connectionDetail, arguments: c.userId),
                      child: _PersonTile(c,
                          subtitle: c.lastMessage ?? 'Say hi 👋',
                          trailing: c.unread > 0 ? Pill('${c.unread}', filled: true) : null),
                    ))
                .toList(),
          );
        }),
      );
}

class ChatView extends GetView<ChatController> {
  const ChatView({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: simpleAppBar(controller.peer.name),
        body: Column(children: [
          Expanded(
            child: Obx(() => ListView(
                  padding: const EdgeInsets.all(16),
                  children: controller.messages
                      .map((m) => Align(
                            alignment: m.fromMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              constraints: const BoxConstraints(maxWidth: 280),
                              decoration: BoxDecoration(
                                color: m.fromMe ? AppColors.violet : AppColors.divider,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(m.text, style: TextStyle(color: m.fromMe ? Colors.white : AppColors.textPrimary)),
                            ),
                          ))
                      .toList(),
                )),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    key: const Key('chat_input'),
                    controller: controller.input,
                    decoration: const InputDecoration(hintText: 'Type a message…'),
                    onSubmitted: (_) => controller.send(),
                  ),
                ),
                IconButton(
                    key: const Key('chat_send'),
                    icon: const Icon(Icons.send, color: AppColors.violet),
                    onPressed: controller.send),
              ]),
            ),
          ),
        ]),
      );
}

class ChatSubscriptionView extends GetView<ChatSubscriptionController> {
  const ChatSubscriptionView({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: simpleAppBar('Chat Pass'),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          const StatusHero(
              icon: Icons.chat_bubble,
              title: 'Unlock Chat',
              color: AppColors.violet,
              subtitle: 'Keep the spark going with your mutual connections.'),
          const SizedBox(height: 24),
          const AppCard(
            child: Column(children: [
              KeyValueRow('Unlimited messages with matches', '✓'),
              KeyValueRow('See who liked you', '✓'),
              KeyValueRow('Priority in live queues', '✓'),
              Divider(),
              KeyValueRow('Monthly', '₹199 / month', bold: true),
            ]),
          ),
          const SizedBox(height: 8),
          const Text('Billed through Google Play. Cancel anytime in Play Store › Subscriptions.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 24),
          Obx(() => GradientButton(
              key: const Key('subscribe'),
              label: controller.busy.value ? 'Processing…' : 'Subscribe',
              onPressed: controller.busy.value ? null : controller.subscribe)),
        ]),
      );
}

class SubscriptionSuccessView extends StatelessWidget {
  const SubscriptionSuccessView({super.key});
  @override
  Widget build(BuildContext context) {
    final peer = Get.arguments;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const StatusHero(
                icon: Icons.check, title: 'Subscription Successful', subtitle: 'Your Chat Pass is active. Start chatting now!'),
            const SizedBox(height: 32),
            GradientButton(
              key: const Key('start_chatting'),
              label: 'Start Chatting',
              onPressed: () => peer is Connection ? Get.offNamed(Routes.chat, arguments: peer) : Get.offAllNamed(Routes.chats),
            ),
          ]),
        ),
      ),
    );
  }
}

class NotificationsView extends GetView<NotificationsController> {
  const NotificationsView({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: simpleAppBar('Notifications'),
        body: Obx(() => controller.items.isEmpty
            ? _empty('No notifications yet.')
            : ListView(
                padding: const EdgeInsets.all(16),
                children: controller.items
                    .map((n) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: AppCard(
                            color: n.read ? Colors.white : AppColors.violet.withOpacity(.05),
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Icon(Icons.notifications, color: AppColors.violet),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(n.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Text(n.body, style: const TextStyle(color: AppColors.textSecondary)),
                                ]),
                              ),
                            ]),
                          ),
                        ))
                    .toList(),
              )),
      );
}
