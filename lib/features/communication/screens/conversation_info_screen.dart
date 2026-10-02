import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/conversation_controller.dart';
import '../models/conversation.dart';
import '../theme/comm_colors.dart';
import '../widgets/comm_avatar.dart';
import '../widgets/conversation_context_banner.dart';
import '../widgets/conversation_context_sheet.dart';
import '../services/group_name.dart';
import 'add_people_screen.dart';
import 'conversation_screen.dart';

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
      // Reactive: a rename or new members (ours or someone else's, via
      // ConversationUpdated) show up without leaving the screen.
      body: Obx(() => ListView(
            children: [
              _headerCard(context, c),
              if (c.detail.value?.hasScope == true) _scopeSection(context, c),
              _pinnedSection(c),
              _membersSection(context, c),
            ],
          )),
    );
  }

  // ── Rename / add people ────────────────────────────────

  Future<void> _rename(BuildContext context, ConversationController c) async {
    final field = TextEditingController(text: c.detail.value?.title ?? '');
    final saved = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename group'),
        content: TextField(
          controller: field,
          autofocus: true,
          maxLength: groupNameMax,
          textInputAction: TextInputAction.done,
          onSubmitted: (v) => Navigator.of(ctx).pop(v),
          decoration: const InputDecoration(
            labelText: 'Group name',
            hintText: 'e.g. Store launch team',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(field.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    // `field` is deliberately not disposed here: the dialog's TextField is still mounted
    // during its closing animation, and disposing now throws "used after disposed".

    final title = saved?.trim() ?? '';
    if (title.isEmpty || title == c.detail.value?.title) return;
    try {
      await c.rename(title);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not rename the group')),
        );
      }
    }
  }

  /// In a group, adds people in place. In a 1:1, a new named group is created and
  /// opened in place of this thread (the direct thread itself stays as it was).
  Future<void> _addPeople(BuildContext context, ConversationController c) async {
    final nav = Navigator.of(context);
    final created = await nav.push<ConversationDetail>(
      MaterialPageRoute(builder: (_) => AddPeopleScreen(controller: c)),
    );
    if (created == null) return;
    nav.pop(); // this info screen
    nav.pushReplacement(MaterialPageRoute(
      builder: (_) => ConversationScreen(
        conversationId: created.id,
        title: created.title ?? 'Group',
      ),
    ));
  }

  Widget _headerCard(BuildContext context, ConversationController c) {
    final d = c.detail.value;
    final title = d?.title ?? 'Conversation';
    return Container(
      color: CommColors.bg,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        children: [
          CommAvatar(name: title, seed: c.conversationId, size: 64),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: CommColors.ink,
                  ),
                ),
              ),
              if (c.canRename)
                IconButton(
                  tooltip: 'Rename group',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.edit_outlined, size: 18, color: CommColors.muted),
                  onPressed: () => _rename(context, c),
                ),
            ],
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

  Widget _scopeSection(BuildContext context, ConversationController c) {
    final d = c.detail.value!;
    final ctx = c.scopeContext.value;
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
            status: d.scopeStatus,
            onTap: ctx == null ? null : () => showConversationContextSheet(context, ctx),
            onOpen: ctx == null ? null : () => openScopeObject(context, ctx),
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

  Widget _membersSection(BuildContext context, ConversationController c) {
    final members = c.detail.value?.members ?? const <ConversationMember>[];
    final isDirect = c.detail.value?.type == ConversationType.oneToOne;
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Members (${members.length})'),
          Container(
            color: CommColors.bg,
            child: Column(
              children: [
                ListTile(
                  onTap: () => _addPeople(context, c),
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: CommColors.blueSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_add_alt_1, size: 20, color: CommColors.blueDark),
                  ),
                  title: Text(
                    isDirect ? 'Create a group with this person' : 'Add people',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: CommColors.blueDark,
                    ),
                  ),
                ),
                ...members.map((m) {
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
              }),
              ],
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
