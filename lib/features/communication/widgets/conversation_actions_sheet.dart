import 'package:flutter/material.dart';

import '../controllers/messenger_controller.dart';
import '../models/conversation.dart';
import '../theme/comm_colors.dart';

/// Long-press actions for an inbox row.
///
/// Only actions with a real backing endpoint appear here. Archive and delete are
/// deliberately absent — the server has no write path for either, so offering them
/// would be a button that silently does nothing.
Future<void> showConversationActions(
  BuildContext context,
  MessengerController c,
  ConversationSummary conv, {
  required VoidCallback onOpen,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        conv.title ?? 'Conversation',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: CommColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: CommColors.line2),
              _action(Icons.open_in_new, 'Open', () {
                Navigator.of(ctx).pop();
                onOpen();
              }),
              if (conv.unreadCount > 0)
                _action(Icons.mark_email_read_outlined, 'Mark as read', () {
                  c.markReadFromInbox(conv.id);
                  Navigator.of(ctx).pop();
                }),
              _action(
                conv.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                conv.isPinned ? 'Unpin' : 'Pin',
                () {
                  c.togglePin(conv.id);
                  Navigator.of(ctx).pop();
                },
              ),
              if (conv.isMuted)
                _action(Icons.volume_up_outlined, 'Unmute', () {
                  c.toggleMute(conv.id, until: null);
                  Navigator.of(ctx).pop();
                })
              else
                _action(Icons.volume_off_outlined, 'Mute', () {
                  Navigator.of(ctx).pop();
                  _pickMuteDuration(context, c, conv.id);
                }),
              if (!conv.isDirect)
                _action(Icons.logout, 'Leave group', () {
                  Navigator.of(ctx).pop();
                  _confirmLeave(context, c, conv);
                }, danger: true),
            ],
          ),
        ),
      );
    },
  );
}

Widget _action(IconData icon, String label, VoidCallback onTap, {bool danger = false}) {
  final color = danger ? CommColors.red : CommColors.ink2;
  return ListTile(
    dense: true,
    leading: Icon(icon, size: 20, color: color),
    title: Text(
      label,
      style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14.5),
    ),
    onTap: onTap,
  );
}

/// Mute is an arbitrary future timestamp server-side, so the presets are purely a
/// client convenience.
void _pickMuteDuration(BuildContext context, MessengerController c, int conversationId) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      void apply(Duration? d) {
        c.toggleMute(
          conversationId,
          // "Until I turn it back on" still needs a concrete date — far enough out to
          // read as indefinite, which is how the web client models it too.
          until: DateTime.now().add(d ?? const Duration(days: 3650)),
        );
        Navigator.of(ctx).pop();
      }

      return Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Mute notifications',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: CommColors.ink,
                    ),
                  ),
                ),
              ),
              const Divider(height: 1, color: CommColors.line2),
              _action(Icons.schedule, 'For 8 hours',
                  () => apply(const Duration(hours: 8))),
              _action(Icons.schedule, 'For 1 week', () => apply(const Duration(days: 7))),
              _action(Icons.notifications_off_outlined, 'Until I turn it back on',
                  () => apply(null)),
            ],
          ),
        ),
      );
    },
  );
}

void _confirmLeave(BuildContext context, MessengerController c, ConversationSummary conv) {
  showDialog<void>(
    context: context,
    builder: (dctx) => AlertDialog(
      title: const Text('Leave conversation?'),
      content: Text(
        'You will stop receiving messages from "${conv.title ?? 'this conversation'}". '
        'Messages you already sent stay visible to the others.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dctx).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(dctx).pop();
            c.leaveConversation(conv.id);
          },
          child: const Text('Leave', style: TextStyle(color: CommColors.red)),
        ),
      ],
    ),
  );
}
