import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/messenger_controller.dart';
import '../models/conversation.dart';
import '../theme/comm_colors.dart';
import '../widgets/comm_avatar.dart';
import '../widgets/connection_banner.dart';
import 'conversation_screen.dart';

/// Inbox: the list of the user's conversations. Entry screen of the messenger tab.
class ConversationsListScreen extends StatelessWidget {
  const ConversationsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Created once by NavigationMenu (permanent) so the realtime channel is up on
    // every tab; fall back to creating it if this screen is ever shown standalone.
    final c = Get.isRegistered<MessengerController>()
        ? Get.find<MessengerController>()
        : Get.put(MessengerController(), permanent: true);

    return Scaffold(
      backgroundColor: CommColors.bg,
      appBar: AppBar(
        backgroundColor: CommColors.bg,
        elevation: 0,
        title: const Text(
          'Messages',
          style: TextStyle(color: CommColors.ink, fontWeight: FontWeight.w700, fontSize: 20),
        ),
        iconTheme: const IconThemeData(color: CommColors.ink),
      ),
      body: Column(
        children: [
          Obx(() => ConnectionBanner(
                status: c.connection.value,
                onRetry: () => c.signalR.connect().catchError((_) {}),
              )),
          Obx(() {
            if (c.pendingOutbox.value == 0) return const SizedBox.shrink();
            return Container(
              width: double.infinity,
              color: CommColors.blueSoft,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Text(
                '${c.pendingOutbox.value} message(s) waiting to send',
                style: const TextStyle(color: CommColors.blueDark, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            );
          }),
          Expanded(
            child: Obx(() {
              if (c.isLoading.value && c.conversations.isEmpty) {
                return const Center(child: CircularProgressIndicator(color: CommColors.blue));
              }
              if (c.hasError.value && c.conversations.isEmpty) {
                return _stateMessage(Icons.wifi_off, 'Could not load conversations',
                    action: TextButton(onPressed: c.loadConversations, child: const Text('Retry')));
              }
              if (c.conversations.isEmpty) {
                return _stateMessage(Icons.forum_outlined, 'No conversations yet');
              }
              return RefreshIndicator(
                color: CommColors.blue,
                onRefresh: c.loadConversations,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: c.conversations.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 76, color: CommColors.line2),
                  itemBuilder: (_, i) => _tile(context, c, c.conversations[i]),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, MessengerController c, ConversationSummary conv) {
    final unread = conv.unreadCount > 0;
    final time = conv.lastMessageAt != null ? _shortTime(conv.lastMessageAt!) : '';
    final preview = conv.lastMessagePreview ?? '';
    final previewText = conv.isDirect || conv.lastMessageSenderName == null
        ? preview
        : '${conv.lastMessageSenderName}: $preview';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CommAvatar(
        name: conv.title,
        seed: conv.id,
        online: conv.isOnline,
        showPresence: conv.isDirect,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              conv.title ?? 'Conversation',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
                color: CommColors.ink,
              ),
            ),
          ),
          Text(time, style: const TextStyle(fontSize: 11.5, color: CommColors.muted2)),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Row(
          children: [
            if (conv.isMuted)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.volume_off, size: 14, color: CommColors.muted2),
              ),
            Expanded(
              child: Text(
                previewText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: unread ? CommColors.ink2 : CommColors.muted,
                  fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (unread)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: CommColors.blue, borderRadius: BorderRadius.circular(999)),
                child: Text(
                  conv.unreadCount > 99 ? '99+' : '${conv.unreadCount}',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      ),
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ConversationScreen(
            conversationId: conv.id,
            title: conv.title ?? 'Conversation',
          ),
        ));
      },
    );
  }

  Widget _stateMessage(IconData icon, String text, {Widget? action}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: CommColors.line),
          const SizedBox(height: 10),
          Text(text, style: const TextStyle(color: CommColors.muted, fontSize: 14)),
          if (action != null) action,
        ],
      ),
    );
  }

  String _shortTime(DateTime dt) {
    final now = DateTime.now();
    final sameDay = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    if (sameDay) return DateFormat('HH:mm').format(dt);
    final yesterday = now.subtract(const Duration(days: 1));
    if (dt.year == yesterday.year && dt.month == yesterday.month && dt.day == yesterday.day) {
      return 'Yesterday';
    }
    return DateFormat('dd/MM').format(dt);
  }
}
