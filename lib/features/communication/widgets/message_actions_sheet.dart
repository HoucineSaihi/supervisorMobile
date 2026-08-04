import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/conversation_controller.dart';
import '../models/message.dart';
import '../theme/comm_colors.dart';

/// Long-press action sheet for a message: a quick-reaction row plus reply / edit /
/// pin / delete. Mirrors the web hover-actions, adapted to a mobile bottom sheet.
Future<void> showMessageActions(
  BuildContext context,
  ConversationController c,
  Message message,
) async {
  await c.loadAllowedReactions();
  final isOwn = message.senderId == c.currentUserId;
  final canEdit = isOwn && message.type == MessageType.text && !message.isDeleted;

  if (!context.mounted) return;
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
              // Quick reactions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: c.allowedReactions.take(6).map((emoji) {
                    return GestureDetector(
                      onTap: () {
                        c.toggleReaction(message.id, emoji);
                        Navigator.of(ctx).pop();
                      },
                      child: Text(emoji, style: const TextStyle(fontSize: 26)),
                    );
                  }).toList(),
                ),
              ),
              const Divider(height: 1, color: CommColors.line2),
              _action(ctx, Icons.reply, 'Reply', () {
                c.startReply(message);
                Navigator.of(ctx).pop();
              }),
              if ((message.body ?? '').trim().isNotEmpty && !message.isDeleted)
                _action(ctx, Icons.copy_all_outlined, 'Copy text', () {
                  Clipboard.setData(ClipboardData(text: message.body!));
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Copied'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }),
              // Turning a report into a tracked incident without leaving the thread is
              // the point of an operational messenger. Already-converted messages link
              // to the existing incident instead of making a second one.
              if (!message.isDeleted && message.linkedIncidentId == null)
                _action(ctx, Icons.report_problem_outlined, 'Convert to incident', () {
                  Navigator.of(ctx).pop();
                  _confirmConvert(context, c, message);
                }),
              if (canEdit)
                _action(ctx, Icons.edit_outlined, 'Edit', () {
                  c.startEdit(message);
                  Navigator.of(ctx).pop();
                }),
              _action(ctx, message.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  message.isPinned ? 'Unpin' : 'Pin', () {
                c.togglePin(message);
                Navigator.of(ctx).pop();
              }),
              if (isOwn && !message.isDeleted)
                _action(ctx, Icons.delete_outline, 'Delete', () {
                  Navigator.of(ctx).pop();
                  _confirmDelete(context, c, message.id);
                }, danger: true),
            ],
          ),
        ),
      );
    },
  );
}

Widget _action(BuildContext ctx, IconData icon, String label, VoidCallback onTap,
    {bool danger = false}) {
  final color = danger ? CommColors.red : CommColors.ink2;
  return ListTile(
    dense: true,
    leading: Icon(icon, size: 20, color: color),
    title: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14.5)),
    onTap: onTap,
  );
}

/// Confirms before raising an incident — this creates a real tracked record, so it
/// should never happen on a stray long-press.
void _confirmConvert(BuildContext context, ConversationController c, Message message) {
  showDialog<void>(
    context: context,
    builder: (dctx) => AlertDialog(
      title: const Text('Convert to incident?'),
      content: Text(
        'A tracked incident will be created from this message'
        '${(message.body ?? '').trim().isEmpty ? '' : ':\n\n"${message.body!.trim()}"'}',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dctx).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.of(dctx).pop();
            final messenger = ScaffoldMessenger.of(context);
            final summary = await c.convertToIncident(message);
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  summary == null
                      ? 'Could not create the incident'
                      : 'Incident INC-${summary.id} created',
                ),
              ),
            );
          },
          child: const Text('Create incident'),
        ),
      ],
    ),
  );
}

void _confirmDelete(BuildContext context, ConversationController c, int messageId) {
  showDialog<void>(
    context: context,
    builder: (dctx) => AlertDialog(
      title: const Text('Delete message?'),
      content: const Text('This message will be removed for everyone.'),
      actions: [
        TextButton(onPressed: () => Navigator.of(dctx).pop(), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            c.deleteMessage(messageId);
            Navigator.of(dctx).pop();
          },
          child: const Text('Delete', style: TextStyle(color: CommColors.red)),
        ),
      ],
    ),
  );
}
