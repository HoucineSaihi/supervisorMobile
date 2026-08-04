import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/conversation.dart';
import '../theme/comm_colors.dart';

/// In-thread card for an incident raised from, or referenced by, a message.
///
/// Deliberately *not* bubble-shaped: square corners, full width and a coloured header
/// so an operational object never reads as someone's chat message.
class IncidentCard extends StatelessWidget {
  final IncidentStatusSummary incident;
  final VoidCallback? onOpen;

  /// Shown while the summary is still being fetched.
  final bool loading;

  const IncidentCard({
    super.key,
    required this.incident,
    this.onOpen,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFB91C1C); // same red the mention pill and badge use
    final closed = incident.isClosed;
    final statusColor = closed ? CommColors.green : accent;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CommColors.line),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 3, offset: Offset(0, 1)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: const Color(0xFFFEF2F2),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.report_problem_outlined,
                      size: 17, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'INCIDENT',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                          color: accent,
                        ),
                      ),
                      Text(
                        'INC-${incident.id}',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: CommColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                if (incident.statusLabel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      incident.statusLabel!,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((incident.description ?? '').trim().isNotEmpty)
                  Text(
                    incident.description!.trim(),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.35,
                      color: CommColors.ink2,
                    ),
                  ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 14,
                  runSpacing: 4,
                  children: [
                    if (incident.boutiqueName != null)
                      _meta(Icons.store_outlined, incident.boutiqueName!),
                    if (incident.assignedToName != null)
                      _meta(Icons.person_outline, incident.assignedToName!),
                    if (incident.declarationDate != null)
                      _meta(
                        Icons.schedule,
                        DateFormat('dd/MM HH:mm').format(incident.declarationDate!),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: CommColors.line2),
          InkWell(
            onTap: onOpen,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Open incident',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: onOpen == null ? CommColors.muted2 : CommColors.blue,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Icon(
                      Icons.open_in_new,
                      size: 14,
                      color: onOpen == null ? CommColors.muted2 : CommColors.blue,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _meta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: CommColors.muted2),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, color: CommColors.muted)),
      ],
    );
  }
}
