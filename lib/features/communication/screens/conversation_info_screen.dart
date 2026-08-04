import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../controllers/conversation_controller.dart';
import '../models/conversation.dart';
import '../theme/comm_colors.dart';
import '../widgets/comm_avatar.dart';
import '../widgets/conversation_context_banner.dart';

/// Everything about a conversation that doesn't belong in the timeline: who is in it,
/// what has been shared, and what has been pinned.
class ConversationInfoScreen extends StatelessWidget {
  final ConversationController controller;

  const ConversationInfoScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;

    return Scaffold(
      backgroundColor: CommColors.bgSoft,
      appBar: AppBar(
        backgroundColor: CommColors.bg,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: CommColors.ink),
        title: const Text(
          'Conversation info',
          style: TextStyle(
            color: CommColors.ink,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      body: ListView(
        children: [
          _headerCard(c),
          if (c.detail.value?.hasScope == true) _scopeSection(c),
          _pinnedSection(c),
          _membersSection(c),
        ],
      ),
    );
  }

  Widget _headerCard(ConversationController c) {
    final d = c.detail.value;
    final title = d?.title ?? 'Conversation';
    return Container(
      color: CommColors.bg,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        children: [
          CommAvatar(name: title, seed: c.conversationId, size: 64),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: CommColors.ink,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${d?.activeMemberCount ?? 0} members',
            style: const TextStyle(fontSize: 13, color: CommColors.muted),
          ),
          if (d?.createdAt != null) ...[
            const SizedBox(height: 2),
            Text(
              'Created ${DateFormat('dd/MM/yyyy').format(d!.createdAt!)}'
              '${d.createdByName != null ? ' by ${d.createdByName}' : ''}',
              style: const TextStyle(fontSize: 11.5, color: CommColors.muted2),
            ),
          ],
        ],
      ),
    );
  }

  Widget _scopeSection(ConversationController c) {
    final d = c.detail.value!;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Linked to'),
          ConversationContextBanner(
            scopeType: d.scopeType,
            scopeId: d.scopeId!,
            incident: c.scopeIncident.value,
          ),
        ],
      ),
    );
  }

  Widget _pinnedSection(ConversationController c) {
    final pins = c.pinnedMessages;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Pinned messages (${pins.length})'),
          Container(
            color: CommColors.bg,
            child: pins.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Nothing pinned yet. Long-press a message to pin it.',
                      style: TextStyle(color: CommColors.muted, fontSize: 13),
                    ),
                  )
                : Column(
                    children: pins.map((p) {
                      final m = p.message;
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.push_pin,
                            size: 18, color: CommColors.amber),
                        title: Text(
                          m.isDeleted ? 'Deleted message' : (m.body ?? 'Attachment'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13.5, color: CommColors.ink2),
                        ),
                        subtitle: Text(
                          '${m.senderName ?? 'Unknown'} · '
                          '${DateFormat('dd/MM HH:mm').format(m.createdAt)}',
                          style: const TextStyle(fontSize: 11.5, color: CommColors.muted2),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _membersSection(ConversationController c) {
    final members = c.detail.value?.members ?? const <ConversationMember>[];
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Members (${members.length})'),
          Container(
            color: CommColors.bg,
            child: Column(
              children: members.map((m) {
                final online = c.isOnline(m.caisseId);
                return ListTile(
                  leading: CommAvatar(
                    name: m.name,
                    seed: m.caisseId,
                    size: 38,
                    online: online,
                    showPresence: true,
                  ),
                  title: Text(
                    m.name ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: CommColors.ink,
                    ),
                  ),
                  subtitle: Text(
                    online ? 'Online' : 'Offline',
                    style: TextStyle(
                      fontSize: 12,
                      color: online ? CommColors.green : CommColors.muted2,
                    ),
                  ),
                  trailing: m.role == 'Admin'
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: CommColors.blueSoft,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Admin',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: CommColors.blueDark,
                            ),
                          ),
                        )
                      : null,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: CommColors.muted,
          ),
        ),
      );
}
