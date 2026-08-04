import 'package:flutter/material.dart';

import '../models/message.dart';
import '../theme/comm_colors.dart';

/// The most recent pinned message, kept visible above the timeline.
///
/// Only one is shown however many are pinned — a stack of banners would eat the screen
/// the conversation needs. The rest live in the info screen.
class PinnedBanner extends StatelessWidget {
  final PinnedMessage pinned;
  final int totalPinned;
  final VoidCallback? onView;
  final VoidCallback? onDismiss;

  const PinnedBanner({
    super.key,
    required this.pinned,
    this.totalPinned = 1,
    this.onView,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final m = pinned.message;
    final preview = m.isDeleted
        ? 'Deleted message'
        : ((m.body ?? '').trim().isNotEmpty
            ? m.body!.trim()
            : _describeAttachment(m));

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: CommColors.bgSoft,
        border: Border(bottom: BorderSide(color: CommColors.line)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.push_pin, size: 16, color: CommColors.amber),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        pinned.pinnedByName != null
                            ? 'Pinned by ${pinned.pinnedByName}'
                            : 'Pinned',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: CommColors.muted,
                        ),
                      ),
                    ),
                    if (totalPinned > 1)
                      Text(
                        '  ·  $totalPinned pinned',
                        style: const TextStyle(fontSize: 11.5, color: CommColors.muted2),
                      ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  preview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.3,
                    color: CommColors.ink2,
                  ),
                ),
              ],
            ),
          ),
          if (onView != null)
            TextButton(
              onPressed: onView,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('View'),
            ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              iconSize: 16,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(6),
              icon: const Icon(Icons.close, color: CommColors.muted2),
              tooltip: 'Hide',
            ),
        ],
      ),
    );
  }

  String _describeAttachment(Message m) {
    if (m.attachments.isEmpty) return '';
    switch (m.attachments.first.kind) {
      case AttachmentKind.image:
        return '📷 Photo';
      case AttachmentKind.voice:
        return '🎤 Voice message';
      case AttachmentKind.file:
        return '📎 ${m.attachments.first.fileName}';
    }
  }
}
