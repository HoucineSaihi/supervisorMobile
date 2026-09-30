
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;

import '../controllers/conversation_controller.dart';
import '../controllers/messenger_controller.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../services/media_cache.dart';
import '../theme/comm_colors.dart';
import '../widgets/auth_image.dart';
import '../widgets/chat_skeleton.dart';
import '../widgets/comm_avatar.dart';
import '../widgets/connection_banner.dart';
import '../widgets/conversation_context_banner.dart';
import '../widgets/message_actions_sheet.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_receipts_sheet.dart';
import '../widgets/pinned_banner.dart';
import '../widgets/voice_player.dart';
import '../widgets/voice_recorder_button.dart';
import '../../incidents/screens/ConsultProblem.dart';
import 'conversation_info_screen.dart';

/// Same-calendar-day check backing the day dividers — mirrors the web
/// isNewDay's `toDateString()` comparison (local time, not UTC).
bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

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
  final _searchField = TextEditingController();
  final _scroll = ScrollController();
  final _tag = UniqueKey().toString();

  // Mention autocomplete: offset of the "@" that opened the menu.
  int _mentionAnchor = -1;

  // The thread list is reversed (offset 0 = the newest message at the bottom), the
  // standard chat layout: it opens at the bottom with no jump, and prepending older
  // pages never moves what the reader is looking at. Only the newest message's key is
  // tracked, to tell "a new message arrived" apart from "older history was added".
  String? _newestKey;

  @override
  void initState() {
    super.initState();
    c = Get.put(ConversationController(widget.conversationId), tag: _tag);
    // Restore anything typed but not sent before the user last left.
    _composer.text = c.draft;
    _composer.addListener(() => c.draft = _composer.text);
    ever(c.messages, (_) => _onMessagesChanged());
    _scroll.addListener(_maybeLoadOlder);
    // Prefill the composer when an edit starts (done here, not in build, to avoid
    // mutating the text controller during a build pass).
    ever(c.editing, (Message? m) {
      if (m != null) {
        _composer.text = m.body ?? '';
        _composer.selection = TextSelection.collapsed(offset: _composer.text.length);
      }
    });
  }

  /// Follows a newly arrived message only when the reader is already at the bottom
  /// (or sent it). Someone reading history is never yanked down, and a prepended
  /// older page changes nothing here.
  void _onMessagesChanged() {
    final newest = c.messages.isEmpty ? null : c.messages.last;
    final key = newest?.clientMessageId;
    if (key == _newestKey) return; // older history prepended, or an in-place update
    _newestKey = key;
    if (newest == null || !_scroll.hasClients) return;
    final nearBottom = _scroll.position.pixels < 150;
    if (nearBottom || newest.senderId == c.currentUserId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _toBottom());
    }
  }

  void _toBottom() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
  }

  /// Reversed list: the top of the history is the max scroll extent.
  void _maybeLoadOlder() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 400) {
      c.loadOlder();
    }
  }

  // ── Send / edit ──────────────────────────────────────────

  void _submit() {
    final staged = c.stagedVoice.value;
    if (staged != null) {
      c.stagedVoice.value = null;
      c.sendVoice(staged.path, staged.durationSeconds, caption: _takeCaption());
      return;
    }

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

  // ── Attachments ──────────────────────────────────────────

  /// Attachment source picker. Any caption already typed rides along with the file,
  /// so the composer is cleared once a send is actually started.
  void _openAttachMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: CommColors.line,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            _attachTile(sheetCtx, Icons.photo_library_outlined, 'Photo library',
                () => _pickImage(ImageSource.gallery)),
            _attachTile(sheetCtx, Icons.photo_camera_outlined, 'Camera',
                () => _pickImage(ImageSource.camera)),
            _attachTile(sheetCtx, Icons.attach_file, 'Document', _pickFile),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _attachTile(BuildContext sheetCtx, IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(color: CommColors.blueSoft, shape: BoxShape.circle),
        child: Icon(icon, color: CommColors.blueDark, size: 19),
      ),
      title: Text(label,
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: CommColors.ink)),
      onTap: () {
        Navigator.of(sheetCtx).pop();
        onTap();
      },
    );
  }

  /// Caption text is consumed by the send, so take and clear it atomically.
  String? _takeCaption() {
    final text = _composer.text.trim();
    if (text.isEmpty) return null;
    _composer.clear();
    c.clearMentions();
    _mentionAnchor = -1;
    return text;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      // Downscale on capture: a modern phone photo is ~8 MB, over the server's 25 MB
      // cap only in bursts but slow on a shop's connection either way.
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (picked == null) return;
      await c.sendImage(picked.path, p.basename(picked.path), caption: _takeCaption());
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the image picker')),
        );
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(withData: false);
      final path = result?.files.single.path;
      if (path == null) return;
      await c.sendFile(path, result!.files.single.name, caption: _takeCaption());
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the file picker')),
        );
      }
    }
  }

  /// Opens an attachment: images full-screen in-app, documents in the platform viewer.
  Future<void> _openAttachment(MessageAttachment a) async {
    if (a.kind == AttachmentKind.image) {
      _showFullScreenImage(a);
      return;
    }
    if (a.kind == AttachmentKind.voice) return; // played inline

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(content: Text('Downloading ${a.fileName}…'), duration: const Duration(seconds: 1)),
    );
    try {
      // Through the size-capped media cache (authorized download, reused on reopen).
      // The file keeps its real extension so the OS picks the right viewer.
      final file = await MediaCache.instance.file(a, extension: p.extension(a.fileName));
      await OpenFile.open(file.path);
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not open ${a.fileName}')),
      );
    }
  }

  void _showFullScreenImage(MessageAttachment a) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (ctx) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            a.fileName,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: Center(
          child: InteractiveViewer(
            minScale: 0.8,
            maxScale: 4,
            // The only place the original loads; everything else shows the thumbnail.
            child: AuthImage(attachment: a, variant: MediaVariant.full, fit: BoxFit.contain),
          ),
        ),
      ),
    ));
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
    _searchField.dispose();
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
          // Which operational object this thread is about — kept directly under the
          // header so the context is never more than a glance away.
          Obx(() {
            final d = c.detail.value;
            if (d == null || !d.hasScope) return const SizedBox.shrink();
            return ConversationContextBanner(
              scopeType: d.scopeType,
              scopeId: d.scopeId!,
              incident: c.scopeIncident.value,
            );
          }),
          Obx(() {
            if (c.searchActive.value) return const SizedBox.shrink();
            if (c.pinnedBannerDismissed.value || c.pinnedMessages.isEmpty) {
              return const SizedBox.shrink();
            }
            return PinnedBanner(
              pinned: c.pinnedMessages.first,
              totalPinned: c.pinnedMessages.length,
              onView: _openInfo,
              onDismiss: () => c.pinnedBannerDismissed.value = true,
            );
          }),
          Expanded(
            child: Obx(() {
              if (c.searchActive.value) return _searchResults();
              if (c.isLoading.value && c.messages.isEmpty) {
                return const ChatSkeleton();
              }
              if (c.hasError.value && c.messages.isEmpty) {
                return _Hint(
                  icon: Icons.wifi_off,
                  text: 'Could not load messages.',
                  action: TextButton(
                    onPressed: c.reload,
                    child: const Text('Retry'),
                  ),
                );
              }
              if (c.messages.isEmpty) {
                return const _Hint(
                  icon: Icons.chat_bubble_outline,
                  text: 'Start the conversation.\nShare updates, photos or documents.',
                );
              }
              // Read inside the Obx body, not just in itemBuilder: the builder
              // callback runs after this closure returns, so touching the map
              // only there would never register it as a dependency and a
              // summary arriving later wouldn't rebuild the list.
              final summaries = Map<int, IncidentStatusSummary>.from(c.incidentSummaries);
              final loadingOlder = c.isLoadingOlder.value;
              return ListView.builder(
                controller: _scroll,
                reverse: true,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                // +1 for the "loading older" spinner, which sits at the top (the end of
                // a reversed list).
                itemCount: c.messages.length + (loadingOlder ? 1 : 0),
                itemBuilder: (_, ri) {
                  if (ri >= c.messages.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                    );
                  }
                  // Reversed: builder index 0 is the newest message.
                  final i = c.messages.length - 1 - ri;
                  final m = c.messages[i];
                  final prev = i > 0 ? c.messages[i - 1] : null;
                  final showAuthor = prev == null || prev.senderId != m.senderId;
                  final isOwn = m.senderId == c.currentUserId;
                  final incident = m.linkedIncidentId != null
                      ? summaries[m.linkedIncidentId]
                      : null;
                  final isNewDay = prev == null || !_isSameDay(prev.createdAt, m.createdAt);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isNewDay) _DayDivider(date: m.createdAt),
                      MessageBubble(
                        message: m,
                        isOwn: isOwn,
                        currentUserId: c.currentUserId,
                        showAuthor: showAuthor,
                        incident: incident,
                        // The incident card opens the incident itself.
                        onOpenIncident: incident == null
                            ? null
                            : () => Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => ConsultProblem(problemId: incident.id),
                                )),
                        onLongPress: m.id > 0 ? () => showMessageActions(context, c, m) : null,
                        onReactionTap: m.id > 0 ? (emoji) => c.toggleReaction(m.id, emoji) : null,
                        onAttachmentTap: _openAttachment,
                        // Read state is the sender's to inspect — the server refuses the
                        // request for anyone else, so only offer it on my own messages.
                        onReceiptTap: isOwn
                            ? () => showMessageReceipts(
                                  context,
                                  conversationId: widget.conversationId,
                                  messageId: m.id,
                                )
                            : null,
                      ),
                    ],
                  );
                },
              );
            }),
          ),
          Obx(() {
            // While searching, the composer would be in the way — the search field
            // takes its place at the bottom of the screen.
            if (c.searchActive.value) return _searchBar();
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _mentionOverlay(),
                _replyEditBar(),
                _stagedVoiceBar(),
                _composerBar(),
              ],
            );
          }),
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
      title: InkWell(
        onTap: _openInfo,
        child: Row(
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
                    style: const TextStyle(
                        color: CommColors.ink, fontWeight: FontWeight.w700, fontSize: 15.5),
                  ),
                  Obx(() {
                    if (c.typingUserIds.isNotEmpty) {
                      return const Text('typing…',
                          style: TextStyle(color: CommColors.blue, fontSize: 12));
                    }
                    // "28 members, 6 online" — membership is the operational context,
                    // presence is the live part.
                    final members = c.detail.value?.activeMemberCount ?? 0;
                    final online = c.onlineMembers.length;
                    final parts = <String>[
                      if (members > 0) '$members members',
                      if (online > 0) '$online online',
                    ];
                    if (parts.isEmpty) return const SizedBox.shrink();
                    return Text(
                      parts.join(', '),
                      style: TextStyle(
                        color: online > 0 ? CommColors.green : CommColors.muted,
                        fontSize: 12,
                        fontWeight: online > 0 ? FontWeight.w600 : FontWeight.w400,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Search in conversation',
          onPressed: () {
            c.openSearch();
            _searchField.clear();
          },
          icon: const Icon(Icons.search),
        ),
        PopupMenuButton<String>(
          tooltip: 'More',
          onSelected: _onMenuSelected,
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'info', child: Text('Conversation info')),
            const PopupMenuItem(value: 'search', child: Text('Search')),
            PopupMenuItem(
              value: 'mute',
              child: Text(
                (c.detail.value?.isMuted ?? false) ? 'Unmute' : 'Mute notifications',
              ),
            ),
            PopupMenuItem(
              value: 'pin',
              child: Text((c.detail.value?.isPinned ?? false) ? 'Unpin' : 'Pin to top'),
            ),
          ],
        ),
      ],
    );
  }

  void _onMenuSelected(String value) {
    final root = Get.find<MessengerController>();
    switch (value) {
      case 'info':
        _openInfo();
        break;
      case 'search':
        c.openSearch();
        _searchField.clear();
        break;
      case 'mute':
        final muted = c.detail.value?.isMuted ?? false;
        root.toggleMute(
          widget.conversationId,
          until: muted ? null : DateTime.now().add(const Duration(days: 7)),
        );
        break;
      case 'pin':
        root.togglePin(widget.conversationId);
        break;
    }
  }

  void _openInfo() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ConversationInfoScreen(controller: c),
    ));
  }

  /// In-thread search bar, replacing the composer while active.
  Widget _searchBar() {
    return Container(
      color: CommColors.bg,
      padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchField,
              autofocus: true,
              onChanged: c.runSearch,
              style: const TextStyle(fontSize: 14.5, color: CommColors.ink2),
              decoration: InputDecoration(
                hintText: 'Search this conversation',
                hintStyle: const TextStyle(color: CommColors.muted2),
                prefixIcon: const Icon(Icons.search, size: 20, color: CommColors.muted2),
                filled: true,
                fillColor: CommColors.bgSoft,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: CommColors.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: CommColors.line),
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              c.closeSearch();
              _searchField.clear();
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Search hits, newest first. Tapping one is not yet a jump-to-message — that needs
  /// paging back to an arbitrary sequence, which the timeline doesn't support yet.
  Widget _searchResults() {
    return Obx(() {
      if (c.isSearching.value) {
        return const Center(child: CircularProgressIndicator(color: CommColors.blue));
      }
      final q = c.searchQuery.value.trim();
      if (q.length < 2) {
        return const _Hint(
          icon: Icons.search,
          text: 'Type at least two characters to search this conversation.',
        );
      }
      if (c.searchResults.isEmpty) {
        return const _Hint(icon: Icons.search_off, text: 'No messages found.');
      }
      return ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: c.searchResults.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: CommColors.line2),
        itemBuilder: (_, i) {
          final m = c.searchResults[i];
          return ListTile(
            dense: true,
            title: Text(
              m.senderName ?? 'Unknown',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: CommColors.ink,
              ),
            ),
            subtitle: Text(
              m.body ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: CommColors.ink2),
            ),
            trailing: Text(
              DateFormat('dd/MM').format(m.createdAt),
              style: const TextStyle(fontSize: 11, color: CommColors.muted2),
            ),
          );
        },
      );
    });
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

  // ── Staged voice preview ──────────────────────────────────

  /// The recorded-but-unsent clip, played back inline (via [VoicePlayer], the same
  /// widget a sent voice bubble uses) so the user can confirm it's the right take
  /// before sending — with a caption typed below it if they want one, and an X to
  /// discard and re-record instead.
  Widget _stagedVoiceBar() {
    return Obx(() {
      final staged = c.stagedVoice.value;
      if (staged == null) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
        decoration: const BoxDecoration(
          color: CommColors.bgSoft,
          border: Border(top: BorderSide(color: CommColors.line)),
        ),
        child: Row(
          children: [
            const Icon(Icons.mic, size: 16, color: CommColors.blue),
            const SizedBox(width: 8),
            Expanded(
              // Keyed on the file path: each new recording is a genuinely different
              // clip, and without a key Flutter would reuse the previous
              // _VoicePlayerState (still pointed at the discarded file) instead of
              // picking up the new one.
              child: VoicePlayer(
                key: ValueKey('staged-voice-${staged.path}'),
                attachment: MessageAttachment(
                  id: 0,
                  kind: AttachmentKind.voice,
                  url: '',
                  fileName: p.basename(staged.path),
                  contentType: 'application/octet-stream',
                  sizeBytes: 0,
                  durationSeconds: staged.durationSeconds,
                  localFilePath: staged.path,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: CommColors.muted),
              onPressed: c.discardStagedVoice,
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
              GestureDetector(
                onTap: _openAttachMenu,
                child: Container(
                  width: 36,
                  height: 44,
                  alignment: Alignment.center,
                  child: const Icon(Icons.add_circle_outline, color: CommColors.blue, size: 24),
                ),
              ),
              // Camera gets its own button rather than living one level down in the
              // attach sheet: photographing a shelf or a fault is the most common
              // thing a supervisor does in-store, and it should cost one tap.
              GestureDetector(
                onTap: () => _pickImage(ImageSource.camera),
                child: Container(
                  width: 36,
                  height: 44,
                  alignment: Alignment.center,
                  child: const Icon(Icons.photo_camera_outlined,
                      color: CommColors.blue, size: 22),
                ),
              ),
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
                // Read every observable unconditionally so the Obx always tracks at
                // least one reactive — a short-circuited `||` used to leave it with
                // none on an empty composer, tripping GetX's improper-use guard.
                return Obx(() {
                  final isEdit = c.editing.value != null;
                  final sending = c.isSending.value;
                  final hasStagedVoice = c.stagedVoice.value != null;

                  // A staged (recorded-but-unsent) voice clip always shows Send —
                  // there's something to submit even with an empty caption.
                  if (hasStagedVoice) {
                    return _circleButton(Icons.send_rounded, sending ? null : _submit);
                  }

                  // Empty composer -> tap-to-record mic; anything typed (or an edit
                  // in progress) -> send/confirm. Matches the standard chat pattern so
                  // the button never needs its own explanatory label.
                  if (!hasText && !isEdit) {
                    return sending
                        ? _circleButton(Icons.send_rounded, null)
                        : VoiceRecorderButton(
                            onStopped: (path, seconds) =>
                                c.stagedVoice.value = StagedVoice(path: path, durationSeconds: seconds),
                          );
                  }

                  return _circleButton(
                    isEdit ? Icons.check : Icons.send_rounded,
                    sending ? null : _submit,
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

/// WhatsApp-style day separator between message groups — "Today" / "Yesterday"
/// for the two most recent days, else a plain dd/MM/yyyy date. Mirrors the web
/// day-pill 1:1: centred stadium chip, muted gray on light gray, sitting above
/// the first message of each new calendar day.
class _DayDivider extends StatelessWidget {
  final DateTime date;

  const _DayDivider({required this.date});

  String get _label {
    final now = DateTime.now();
    if (_isSameDay(date, now)) return 'Today';
    final yesterday = now.subtract(const Duration(days: 1));
    if (_isSameDay(date, yesterday)) return 'Yesterday';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 18),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: CommColors.line2,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            _label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: CommColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}

/// Centred icon + message used for the thread's empty, error and search states.
class _Hint extends StatelessWidget {
  final IconData icon;
  final String text;
  final Widget? action;

  const _Hint({required this.icon, required this.text, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 38, color: CommColors.line),
            const SizedBox(height: 10),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: CommColors.muted, fontSize: 13.5, height: 1.4),
            ),
            if (action != null) action!,
          ],
        ),
      ),
    );
  }
}
