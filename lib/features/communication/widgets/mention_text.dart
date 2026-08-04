import 'package:flutter/material.dart';

import '../models/message.dart';
import '../theme/comm_colors.dart';
import 'scope_visuals.dart';

/// Builds the inline spans for a message body, turning stored `@[Type:Id]` tokens
/// into styled pills. Same contract as the web `toSegments`: the server sends
/// mentions as positioned rows (startIndex/length), so a renamed entity shows its
/// current label without re-parsing the text. Offsets are validated, not trusted.
List<InlineSpan> buildMentionSpans(
  String body,
  List<MentionRef> mentions, {
  required Color baseColor,
  required int currentUserId,
}) {
  if (mentions.isEmpty) {
    return [TextSpan(text: body, style: TextStyle(color: baseColor))];
  }

  final ordered = mentions
      .where((m) => m.startIndex >= 0 && m.length > 0 && m.startIndex + m.length <= body.length)
      .toList()
    ..sort((a, b) => a.startIndex.compareTo(b.startIndex));

  final spans = <InlineSpan>[];
  var cursor = 0;

  for (final m in ordered) {
    if (m.startIndex < cursor) continue; // overlapping — keep the first
    if (m.startIndex > cursor) {
      spans.add(TextSpan(text: body.substring(cursor, m.startIndex), style: TextStyle(color: baseColor)));
    }
    final label = m.label ?? body.substring(m.startIndex, m.startIndex + m.length);
    spans.add(WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: _MentionPill(
        label: label,
        entityType: m.entityType,
        isMe: m.entityType == 'User' && m.entityId == currentUserId,
        gone: !m.isAvailable,
      ),
    ));
    cursor = m.startIndex + m.length;
  }
  if (cursor < body.length) {
    spans.add(TextSpan(text: body.substring(cursor), style: TextStyle(color: baseColor)));
  }
  return spans;
}

class _MentionPill extends StatelessWidget {
  final String label;
  final String entityType;
  final bool isMe;
  final bool gone;

  const _MentionPill({
    required this.label,
    required this.entityType,
    required this.isMe,
    required this.gone,
  });

  @override
  Widget build(BuildContext context) {
    // Shared with the inbox's origin badge so the two never drift apart.
    final visuals = scopeVisualsFor(entityType);
    final fg = isMe
        ? Colors.white
        : (gone ? CommColors.muted : visuals.fg);
    final bg = isMe
        ? CommColors.blue
        : (gone ? CommColors.line2 : visuals.bg);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(5)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(visuals.icon, size: 12, color: fg),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              decoration: gone ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      ),
    );
  }
}
