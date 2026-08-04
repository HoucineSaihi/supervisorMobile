import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/conversation.dart' show IncidentStatusSummary;
import '../models/message.dart';
import '../theme/comm_colors.dart';
import 'auth_image.dart';
import 'incident_card.dart';
import 'mention_text.dart';
import 'voice_player.dart';

/// A single message row. Own messages align right on a blue bubble with receipt
/// ticks; others align left with the sender's name. Matches the web bubble layout.
class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isOwn;
  final int currentUserId;
  final bool showAuthor;
  final VoidCallback? onLongPress;
  final void Function(String emoji)? onReactionTap;

  /// Opens an image full-screen or downloads a file attachment.
  final void Function(MessageAttachment attachment)? onAttachmentTap;

  /// Opens the "seen by" popup. Only wired for the sender's own messages.
  final VoidCallback? onReceiptTap;

  /// Live status for [Message.linkedIncidentId], when it has been resolved. Null while
  /// loading or if the lookup failed — the card is simply omitted rather than faked.
  final IncidentStatusSummary? incident;
  final VoidCallback? onOpenIncident;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isOwn,
    required this.currentUserId,
    this.showAuthor = true,
    this.onLongPress,
    this.onReactionTap,
    this.onAttachmentTap,
    this.onReceiptTap,
    this.incident,
    this.onOpenIncident,
  });

  bool get _mentionsMe =>
      message.mentions.any((m) => m.entityType == 'User' && m.entityId == currentUserId);

  @override
  Widget build(BuildContext context) {
    // System events are the app talking, not a person — a centred pill keeps them
    // clearly outside the human conversation.
    if (message.type == MessageType.system) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: CommColors.line2,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, size: 13, color: CommColors.muted),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    message.body ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: CommColors.muted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final bubbleColor = isOwn ? CommColors.blueSoft : Colors.white;
    final textColor = CommColors.ink2;

    return Align(
      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        // Operational cards get more room than plain chat — they carry more to read.
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * (incident != null ? 0.9 : 0.78),
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isOwn && showAuthor)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 3),
                child: Text(
                  message.senderName ?? 'Unknown',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: CommColors.ink),
                ),
              ),
            GestureDetector(
              onLongPress: message.isDeleted ? null : onLongPress,
              child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: message.isDeleted ? CommColors.line2 : bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isOwn ? 14 : 4),
                  bottomRight: Radius.circular(isOwn ? 4 : 14),
                ),
                boxShadow: const [
                  BoxShadow(color: Color(0x08000000), blurRadius: 2, offset: Offset(0, 1)),
                ],
                // Left accent when this message names me — the "smart" in-thread cue.
                border: _mentionsMe
                    ? const Border(left: BorderSide(color: CommColors.blue, width: 3))
                    : Border.all(color: isOwn ? const Color(0xFFDBEAFE) : CommColors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.replyToPreview != null) _replyPreview(),
                  if (message.attachments.isNotEmpty) _attachments(),
                  if (message.isDeleted)
                    const Text('This message was deleted',
                        style: TextStyle(color: CommColors.muted, fontStyle: FontStyle.italic, fontSize: 13))
                  else if ((message.body ?? '').isNotEmpty)
                    RichText(
                      text: TextSpan(
                        style: TextStyle(color: textColor, fontSize: 14, height: 1.4),
                        children: buildMentionSpans(
                          message.body!,
                          message.mentions,
                          baseColor: textColor,
                          currentUserId: currentUserId,
                        ),
                      ),
                    ),
                  const SizedBox(height: 3),
                  _footer(),
                ],
              ),
            ),
            ),
            // The incident this message produced or refers to, rendered as an object
            // card rather than folded into the bubble.
            if (incident != null)
              IncidentCard(incident: incident!, onOpen: onOpenIncident),
            if (message.reactions.isNotEmpty) _reactionChips(),
          ],
        ),
      ),
    );
  }

  Widget _reactionChips() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: message.reactions.map((r) {
          return GestureDetector(
            onTap: onReactionTap == null ? null : () => onReactionTap!(r.emoji),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: r.reactedByMe ? CommColors.blueSoft : CommColors.line2,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: r.reactedByMe ? CommColors.blue : CommColors.line,
                ),
              ),
              child: Text(
                '${r.emoji} ${r.count}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: r.reactedByMe ? CommColors.blueDark : CommColors.ink2,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Small pin marker shown in the footer for pinned messages.
  Widget _pinMark() => const Padding(
        padding: EdgeInsets.only(right: 4),
        child: Icon(Icons.push_pin, size: 11, color: CommColors.amber),
      );

  Widget _replyPreview() {
    final r = message.replyToPreview!;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(6),
        border: const Border(left: BorderSide(color: CommColors.blue, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(r.senderName ?? '',
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: CommColors.blueDark)),
          Text(
            r.isDeleted ? 'Deleted message' : (r.snippet ?? ''),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: CommColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _attachments() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: message.attachments.map((a) {
          switch (a.kind) {
            case AttachmentKind.image:
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: GestureDetector(
                  onTap: onAttachmentTap == null ? null : () => onAttachmentTap!(a),
                  child: AuthImage(relativeUrl: a.url, width: 220, height: 170),
                ),
              );
            case AttachmentKind.voice:
              return VoicePlayer(attachment: a, isOwn: isOwn);
            case AttachmentKind.file:
              return GestureDetector(
                onTap: onAttachmentTap == null ? null : () => onAttachmentTap!(a),
                child: _chip(Icons.insert_drive_file_outlined, a.fileName),
              );
          }
        }).toList(),
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CommColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: CommColors.blue),
          const SizedBox(width: 8),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5))),
        ],
      ),
    );
  }

  Widget _footer() {
    final time = DateFormat('HH:mm').format(message.createdAt);
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (message.isPinned) _pinMark(),
        if (message.editCount > 0) ...[
          const Text('edited', style: TextStyle(fontSize: 10, color: CommColors.muted2)),
          const SizedBox(width: 4),
        ],
        Text(time, style: const TextStyle(fontSize: 10.5, color: CommColors.muted2)),
        if (isOwn) ...[
          const SizedBox(width: 4),
          _receipt(),
        ],
      ],
    );
  }

  Widget _receipt() {
    switch (message.pendingStatus) {
      case PendingStatus.sending:
        return const Icon(Icons.schedule, size: 13, color: CommColors.muted2);
      case PendingStatus.queued:
        return const Icon(Icons.access_time, size: 13, color: CommColors.amber);
      case PendingStatus.failed:
        return const Icon(Icons.error_outline, size: 13, color: CommColors.red);
      case null:
        break;
    }

    // Group "3/5" where a tick alone can't convey who is still missing.
    final countLabel = message.recipientCount > 1 ? '${message.readCount}/${message.recipientCount}' : null;
    final read = message.isRead;
    // Tapping the ticks opens the per-person breakdown. Only meaningful once the
    // message exists server-side (id > 0) and there is someone else to have read it.
    final canOpenReceipts = onReceiptTap != null && message.id > 0 && message.recipientCount > 0;
    return GestureDetector(
      onTap: canOpenReceipts ? onReceiptTap : null,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (countLabel != null) ...[
            Text(countLabel, style: const TextStyle(fontSize: 10, color: CommColors.muted2, fontWeight: FontWeight.w600)),
            const SizedBox(width: 2),
          ],
          Icon(
            read ? Icons.done_all : Icons.check,
            size: 14,
            color: read ? CommColors.blue : CommColors.muted2,
          ),
        ],
      ),
    );
  }
}
