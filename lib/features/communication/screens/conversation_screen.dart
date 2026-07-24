import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/conversation_controller.dart';
import '../controllers/messenger_controller.dart';
import '../models/message.dart';
import '../theme/comm_colors.dart';
import '../widgets/comm_avatar.dart';
import '../widgets/connection_banner.dart';
import '../widgets/message_actions_sheet.dart';
import '../widgets/message_bubble.dart';

/// A single conversation thread: message timeline + composer. Realtime, with read
/// receipts, presence, mentions, reactions, replies, voice notes and offline-queued
/// sends via [ConversationController].
class ConversationScreen extends StatefulWidget {
  final int conversationId;
  final String title;

  const ConversationScreen({super.key, required this.conversationId, required this.title});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  late final ConversationController c;
  final _composer = TextEditingController();
  final _scroll = ScrollController();
  final _tag = UniqueKey().toString();

  // Mention autocomplete: offset of the "@" that opened the menu.
  int _mentionAnchor = -1;

  @override
  void initState() {
    super.initState();
    c = Get.put(ConversationController(widget.conversationId), tag: _tag);
    ever(c.messages, (_) => WidgetsBinding.instance.addPostFrameCallback((_) => _toBottom()));
    // Prefill the composer when an edit starts (done here, not in build, to avoid
    // mutating the text controller during a build pass).
    ever(c.editing, (Message? m) {
      if (m != null) {
        _composer.text = m.body ?? '';
        _composer.selection = TextSelection.collapsed(offset: _composer.text.length);
      }
    });
  }

  void _toBottom() {
    if (_scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  // ── Send / edit ──────────────────────────────────────────

  void _submit() {
    final text = _composer.text;
    if (text.trim().isEmpty) return;
    if (c.editing.value != null) {
      c.submitEdit(text);
    } else {
      c.send(text);
    }
    _composer.clear();
    c.clearMentions();
    _mentionAnchor = -1;
  }

  // ── Mention autocomplete ─────────────────────────────────

  void _onComposerChanged(String text) {
    c.notifyTyping();
    final caret = _composer.selection.baseOffset;
    final anchor = _findMentionAnchor(text, caret < 0 ? text.length : caret);
    if (anchor < 0) {
      _mentionAnchor = -1;
      c.clearMentions();
      return;
    }
    _mentionAnchor = anchor;
    final query = text.substring(anchor + 1, caret < 0 ? text.length : caret);
    c.queryMentions(query);
  }

  /// Index of the "@" starting the token under the caret, or -1. The "@" must be at
  /// a word boundary and the partial term must not contain whitespace. Mirrors the
  /// web findMentionAnchor.
  int _findMentionAnchor(String text, int caret) {
    for (var i = caret - 1; i >= 0 && caret - i <= 40; i--) {
      final ch = text[i];
      if (ch == '@') {
        final before = i > 0 ? text[i - 1] : ' ';
        return (i == 0 || RegExp(r'\s').hasMatch(before)) ? i : -1;
      }
      if (RegExp(r'\s').hasMatch(ch)) return -1;
    }
    return -1;
  }

  void _pickMention(MentionSuggestion s) {
    if (_mentionAnchor < 0) return;
    final text = _composer.text;
    final caret = _composer.selection.baseOffset;
    final end = caret < 0 ? text.length : caret;
    final before = text.substring(0, _mentionAnchor);
    final after = text.substring(end);
    final inserted = '${s.token} ';
    final newText = '$before$inserted$after';
    _composer.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: before.length + inserted.length),
    );
    _mentionAnchor = -1;
    c.clearMentions();
  }

  @override
  void dispose() {
    Get.delete<ConversationController>(tag: _tag);
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CommColors.bg,
      appBar: _appBar(),
      body: Column(
        children: [
          Obx(() => ConnectionBanner(
                status: c.connection.value,
                onRetry: () => Get.find<MessengerController>().signalR.connect().catchError((_) {}),
              )),
          Expanded(
            child: Obx(() {
              if (c.isLoading.value && c.messages.isEmpty) {
                return const Center(child: CircularProgressIndicator(color: CommColors.blue));
              }
              if (c.hasError.value && c.messages.isEmpty) {
                return const Center(
                  child: Text('Could not load messages', style: TextStyle(color: CommColors.muted)),
                );
              }
              if (c.messages.isEmpty) {
                return const Center(
                  child: Text('No messages yet — say hello', style: TextStyle(color: CommColors.muted)),
                );
              }
              return ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                itemCount: c.messages.length,
                itemBuilder: (_, i) {
                  final m = c.messages[i];
                  final prev = i > 0 ? c.messages[i - 1] : null;
                  final showAuthor = prev == null || prev.senderId != m.senderId;
                  return MessageBubble(
                    message: m,
                    isOwn: m.senderId == c.currentUserId,
                    currentUserId: c.currentUserId,
                    showAuthor: showAuthor,
                    onLongPress: m.id > 0 ? () => showMessageActions(context, c, m) : null,
                    onReactionTap: m.id > 0 ? (emoji) => c.toggleReaction(m.id, emoji) : null,
                  );
                },
              );
            }),
          ),
          _mentionOverlay(),
          _replyEditBar(),
          _composerBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      backgroundColor: CommColors.bg,
      elevation: 0.5,
      iconTheme: const IconThemeData(color: CommColors.ink),
      titleSpacing: 0,
      title: Row(
        children: [
          CommAvatar(name: widget.title, seed: widget.conversationId, size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: CommColors.ink, fontWeight: FontWeight.w700, fontSize: 15.5),
                ),
                Obx(() {
                  if (c.typingUserIds.isNotEmpty) {
                    return const Text('typing…', style: TextStyle(color: CommColors.blue, fontSize: 12));
                  }
                  final online = c.onlineMembers.length;
                  if (online > 0) {
                    return Text('$online online',
                        style: const TextStyle(color: CommColors.green, fontSize: 12, fontWeight: FontWeight.w600));
                  }
                  return const SizedBox.shrink();
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Mention suggestion list (above the composer) ─────────

  Widget _mentionOverlay() {
    return Obx(() {
      if (c.mentionSuggestions.isEmpty) return const SizedBox.shrink();
      return Container(
        constraints: const BoxConstraints(maxHeight: 220),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: CommColors.line)),
        ),
        child: ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: c.mentionSuggestions.length,
          itemBuilder: (_, i) {
            final s = c.mentionSuggestions[i];
            return ListTile(
              dense: true,
              visualDensity: const VisualDensity(vertical: -2),
              leading: Icon(_mentionIcon(s.entityType), size: 18, color: CommColors.blue),
              title: Text(s.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
              subtitle: s.context != null
                  ? Text(s.context!, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5))
                  : null,
              trailing: Text(s.entityType.toUpperCase(),
                  style: const TextStyle(fontSize: 9, color: CommColors.muted2, fontWeight: FontWeight.w700)),
              onTap: () => _pickMention(s),
            );
          },
        ),
      );
    });
  }

  IconData _mentionIcon(String type) {
    switch (type) {
      case 'Incident':
        return Icons.report_problem_outlined;
      case 'Mission':
        return Icons.assignment_outlined;
      case 'Campaign':
        return Icons.campaign_outlined;
      case 'Boutique':
        return Icons.store_outlined;
      default:
        return Icons.person_outline;
    }
  }

  // ── Reply / edit context bar ─────────────────────────────

  Widget _replyEditBar() {
    return Obx(() {
      final reply = c.replyingTo.value;
      final edit = c.editing.value;
      if (reply == null && edit == null) return const SizedBox.shrink();

      final isEdit = edit != null;
      final target = edit ?? reply!;
      return Container(
        padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
        decoration: const BoxDecoration(
          color: CommColors.bgSoft,
          border: Border(top: BorderSide(color: CommColors.line)),
        ),
        child: Row(
          children: [
            Icon(isEdit ? Icons.edit_outlined : Icons.reply, size: 16, color: CommColors.blue),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isEdit ? 'Editing message' : 'Replying to ${target.senderName ?? ''}',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: CommColors.blueDark)),
                  Text(target.body ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: CommColors.muted)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: CommColors.muted),
              onPressed: () {
                if (isEdit) {
                  c.cancelEdit();
                  _composer.clear();
                } else {
                  c.cancelReply();
                }
              },
            ),
          ],
        ),
      );
    });
  }

  // ── Composer ─────────────────────────────────────────────

  Widget _composerBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: const BoxDecoration(
          color: CommColors.bg,
          border: Border(top: BorderSide(color: CommColors.line)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: CommColors.bgSoft,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: CommColors.line),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: TextField(
                  controller: _composer,
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.newline,
                  onChanged: _onComposerChanged,
                  decoration: const InputDecoration(
                    hintText: 'Message…  (@ to mention)',
                    hintStyle: TextStyle(color: CommColors.muted2),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  style: const TextStyle(fontSize: 14.5, color: CommColors.ink2),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _composer,
              builder: (_, value, __) {
                final hasText = value.text.trim().isNotEmpty;
                // Read both observables unconditionally so the Obx always tracks at
                // least one reactive — a short-circuited `||` used to leave it with
                // none on an empty composer, tripping GetX's improper-use guard.
                return Obx(() {
                  final isEdit = c.editing.value != null;
                  final sending = c.isSending.value;
                  final disabled = (!hasText && !isEdit) || sending;
                  return _circleButton(
                    isEdit ? Icons.check : Icons.send_rounded,
                    disabled ? null : _submit,
                  );
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: onTap == null ? CommColors.muted2 : CommColors.blue,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
