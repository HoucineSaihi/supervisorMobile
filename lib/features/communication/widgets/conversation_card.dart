import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/conversation.dart';
import '../models/message.dart' show MessagePriority;
import '../theme/comm_colors.dart';
import 'comm_avatar.dart';
import 'scope_visuals.dart';

/// One row in the inbox.
///
/// Deliberately presentational — swipe and long-press behaviour are attached by the
/// caller, so the same row renders identically in the pinned block and the main list.
class ConversationCard extends StatelessWidget {
  final ConversationSummary conversation;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const ConversationCard({
    super.key,
    required this.conversation,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final c = conversation;
    final unread = c.unreadCount > 0;

    final preview = c.lastMessagePreview ?? '';
    // Group traffic needs "who said it"; a 1:1 obviously doesn't.
    final previewText = c.isDirect || c.lastMessageSenderName == null
        ? preview
        : '${c.lastMessageSenderName}: $preview';

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CommAvatar(
              name: c.title,
              seed: c.id,
              online: c.isOnline,
              showPresence: c.isDirect,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (c.isUrgent) ...[
                        _PriorityDot(priority: c.highestUnreadPriority!),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          c.title ?? 'Conversation',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
                            color: CommColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        c.lastMessageAt != null ? _shortTime(c.lastMessageAt!) : '',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: unread ? CommColors.blue : CommColors.muted2,
                          fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          previewText,
                          // Two lines, per the inbox spec — enough to judge a message
                          // without opening it, short enough to keep the list scannable.
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.3,
                            color: unread ? CommColors.ink2 : CommColors.muted,
                            fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _TrailingFlags(conversation: c),
                    ],
                  ),
                  if (c.hasScope || c.hasUnreadMention) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (c.hasScope) _ScopeBadge(scopeType: c.scopeType),
                        if (c.hasScope && c.hasUnreadMention) const SizedBox(width: 6),
                        if (c.hasUnreadMention) const _MentionBadge(),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
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

/// Mute / pin markers and the unread count, stacked at the row's trailing edge.
class _TrailingFlags extends StatelessWidget {
  final ConversationSummary conversation;

  const _TrailingFlags({required this.conversation});

  @override
  Widget build(BuildContext context) {
    final c = conversation;
    final unread = c.unreadCount > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (unread)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              // A muted thread still counts, but shouldn't shout.
              color: c.isMuted ? CommColors.muted2 : CommColors.blue,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              c.unreadCount > 99 ? '99+' : '${c.unreadCount}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        if (c.isMuted || c.isPinned) ...[
          if (unread) const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (c.isPinned)
                const Icon(Icons.push_pin, size: 13, color: CommColors.muted2),
              if (c.isPinned && c.isMuted) const SizedBox(width: 3),
              if (c.isMuted)
                const Icon(Icons.volume_off, size: 13, color: CommColors.muted2),
            ],
          ),
        ],
      ],
    );
  }
}

/// Where the thread came from — an Incident, a store, a campaign.
class _ScopeBadge extends StatelessWidget {
  final ConversationScopeType scopeType;

  const _ScopeBadge({required this.scopeType});

  @override
  Widget build(BuildContext context) {
    final name = scopeTypeToJson(scopeType);
    final v = scopeVisualsFor(name);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: v.bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(v.icon, size: 11, color: v.fg),
          const SizedBox(width: 3),
          Text(
            scopeLabelFor(name),
            style: TextStyle(color: v.fg, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _MentionBadge extends StatelessWidget {
  const _MentionBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: CommColors.blueSoft,
        borderRadius: BorderRadius.circular(5),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.alternate_email, size: 11, color: CommColors.blueDark),
          SizedBox(width: 3),
          Text(
            'Mentioned',
            style: TextStyle(
              color: CommColors.blueDark,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Urgency marker for unread traffic. Only ever drawn above Normal.
class _PriorityDot extends StatelessWidget {
  final MessagePriority priority;

  const _PriorityDot({required this.priority});

  @override
  Widget build(BuildContext context) {
    final Color color;
    switch (priority) {
      case MessagePriority.critical:
        color = const Color(0xFFB91C1C); // deepest red — matches Incident styling
        break;
      case MessagePriority.urgent:
        color = CommColors.red;
        break;
      case MessagePriority.important:
        color = CommColors.amber;
        break;
      case MessagePriority.normal:
        color = Colors.transparent;
        break;
    }
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
