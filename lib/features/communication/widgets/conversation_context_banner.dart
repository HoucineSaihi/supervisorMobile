import 'package:flutter/material.dart';

import '../models/conversation.dart';
import '../theme/comm_colors.dart';
import 'scope_visuals.dart';

/// Strip under the header naming the operational object a thread belongs to.
///
/// Without it a context thread looks like any other group chat — this is what keeps
/// "what are we actually discussing" answerable at a glance.
class ConversationContextBanner extends StatelessWidget {
  final ConversationScopeType scopeType;
  final int scopeId;

  /// Incident details (description, store, assignee), when the thread is about one.
  final IncidentStatusSummary? incident;

  /// Open/closed status of the object, from the conversation itself — covers
  /// incidents, VM campaigns, VM executions and missions alike.
  final ScopeStatus? status;

  /// The "Open" button: straight to the incident / campaign / mission screen.
  final VoidCallback? onOpen;

  /// Tapping the strip itself: the context sheet with the object's key facts.
  final VoidCallback? onTap;

  const ConversationContextBanner({
    super.key,
    required this.scopeType,
    required this.scopeId,
    this.incident,
    this.status,
    this.onOpen,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = scopeTypeToJson(scopeType);
    final v = scopeVisualsFor(name);
    final label = scopeLabelFor(name);

    // Prefer the resolved object's own description; fall back to its id.
    final title = incident?.description?.trim().isNotEmpty == true
        ? incident!.description!.trim()
        : '$label #$scopeId';

    // The conversation's own status first: it is what the read-only lock follows.
    final pillLabel = status?.label ?? incident?.statusLabel;
    final pillClosed = status?.isClosed ?? incident?.isClosed ?? false;

    return Material(
      color: v.bg,
      child: InkWell(
        onTap: onTap,
        child: Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      child: Row(
        children: [
          Icon(v.icon, size: 18, color: v.fg),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: v.fg,
                      ),
                    ),
                    if (pillLabel != null) ...[
                      const SizedBox(width: 6),
                      _StatusPill(label: pillLabel, closed: pillClosed),
                    ],
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CommColors.ink,
                  ),
                ),
                if (incident?.boutiqueName != null || incident?.assignedToName != null)
                  Text(
                    [
                      if (incident?.boutiqueName != null) incident!.boutiqueName!,
                      if (incident?.assignedToName != null) '· ${incident!.assignedToName!}',
                    ].join(' '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11.5, color: CommColors.muted),
                  ),
              ],
            ),
          ),
          if (onOpen != null)
            TextButton(
              onPressed: onOpen,
              style: TextButton.styleFrom(
                foregroundColor: v.fg,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Open', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          if (onTap != null && onOpen == null)
            Icon(Icons.chevron_right, size: 20, color: v.fg),
        ],
      ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final bool closed;

  const _StatusPill({required this.label, required this.closed});

  @override
  Widget build(BuildContext context) {
    final color = closed ? CommColors.green : CommColors.amber;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Closed = the thread is read-only.
          if (closed) ...[
            Icon(Icons.lock_outline, size: 10, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}
