import 'dart:async';
import 'dart:math';

import 'package:get/get.dart';

import '../models/conversation.dart';
import '../models/message.dart';
import '../services/chat_signalr_service.dart';
import '../services/messenger_service.dart';
import '../services/offline_queue.dart';
import 'messenger_controller.dart';

/// Per-thread state: the message list, composer send (with offline queueing),
/// realtime updates, read receipts and presence. Created when a conversation opens
/// and disposed on close.
class ConversationController extends GetxController {
  ConversationController(this.conversationId);

  final int conversationId;

  final MessengerController _root = Get.find<MessengerController>();
  MessengerService get _service => _root.service;
  ChatSignalRService get _signalR => _root.signalR;
  OfflineQueue get _queue => _root.queue;
  int get currentUserId => _root.currentUserId;

  final messages = <Message>[].obs;
  final detail = Rxn<ConversationDetail>();
  final isLoading = false.obs;
  final hasError = false.obs;
  final isSending = false.obs;
  final onlineMembers = <int>{}.obs;
  final typingUserIds = <int>{}.obs;
  final connection = ConnectionStatus.connecting.obs;

  // Compose-side state (Phase G follow-up).
  final replyingTo = Rxn<Message>();
  final editing = Rxn<Message>();
  final mentionSuggestions = <MentionSuggestion>[].obs;
  final allowedReactions = <String>[].obs;
  Timer? _mentionDebounce;

  int _lastSequence = 0;
  bool _isResyncing = false;
  final _rng = Random();

  final _subs = <StreamSubscription>[];
  final _typingTimers = <int, Timer>{};

  @override
  void onInit() {
    super.onInit();
    connection.value = _signalR.status;
    _subscribe();
    _open();
  }

  Future<void> _open() async {
    isLoading.value = true;
    hasError.value = false;
    _loadPresence();
    try {
      final page = await _service.getMessages(conversationId, pageSize: 50);
      messages.value = page.messages;
      _trackSequence(page.messages);
      _mergeQueued();
      isLoading.value = false;
      markRead();
    } catch (_) {
      isLoading.value = false;
      hasError.value = true;
    }
    // Fetch detail (members) in parallel; failure is non-fatal.
    try {
      detail.value = await _service.getConversation(conversationId);
    } catch (_) {}
    // Subscribe BEFORE joining so a join failure mid-reconnect can't skip wiring.
    await _signalR.joinConversation(conversationId);
    _root.markConversationRead(conversationId);
    // Suppress the global toast for the thread that's now on screen.
    _root.setActiveConversation(conversationId);
  }

  void _subscribe() {
    _subs.add(_signalR.onStatus.listen((s) => connection.value = s));

    _subs.add(_signalR.onMessage.listen((m) {
      if (m.conversationId != conversationId) return;
      final i = messages.indexWhere((x) => x.clientMessageId == m.clientMessageId);
      if (i >= 0) {
        messages[i] = m;
      } else {
        messages.add(m);
      }
      _trackSequence([m]);
      messages.refresh();
      if (m.senderId != currentUserId) markRead();
    }));

    _subs.add(_signalR.onResyncRequired.listen((_) => _resync()));

    _subs.add(_signalR.onThreadEvent.listen((e) {
      if (e.conversationId != conversationId) return;
      _refreshMessage(e.messageId);
    }));

    _subs.add(_signalR.onStatusChanged.listen((messageId) => _refreshMessage(messageId)));

    _subs.add(_signalR.onConversationRead.listen((e) {
      if (e.conversationId != conversationId || e.caisseId == currentUserId) return;
      _applyReadWatermark(e.lastReadSequence);
    }));

    _subs.add(_signalR.onPresence.listen((e) {
      if (e.isOnline) {
        onlineMembers.add(e.caisseId);
      } else {
        onlineMembers.remove(e.caisseId);
      }
      onlineMembers.refresh();
    }));

    _subs.add(_signalR.onTyping.listen((caisseId) {
      if (caisseId == currentUserId) return;
      typingUserIds.add(caisseId);
      typingUserIds.refresh();
      _typingTimers[caisseId]?.cancel();
      _typingTimers[caisseId] = Timer(const Duration(seconds: 4), () {
        typingUserIds.remove(caisseId);
        typingUserIds.refresh();
      });
    }));
  }

  void _trackSequence(List<Message> list) {
    for (final m in list) {
      if (m.sequenceNumber > _lastSequence) _lastSequence = m.sequenceNumber;
    }
  }

  Future<void> _mergeQueued() async {
    final queued = await _queue.pending(conversationId: conversationId);
    for (final q in queued) {
      if (messages.any((m) => m.clientMessageId == q.clientMessageId)) continue;
      messages.add(Message(
        id: -DateTime.now().millisecondsSinceEpoch,
        conversationId: conversationId,
        sequenceNumber: 1 << 30,
        clientMessageId: q.clientMessageId,
        senderId: currentUserId,
        type: MessageType.text,
        body: q.body,
        createdAt: q.createdAt,
        pendingStatus: PendingStatus.queued,
      ));
    }
    messages.refresh();
  }

  /// Pulls anything sent while the socket was down. SignalR replays nothing across a
  /// reconnect, so without this a gap stays invisible.
  Future<void> _resync() async {
    if (_isResyncing || _lastSequence == 0) return;
    _isResyncing = true;
    try {
      final page = await _service.getMessages(conversationId, afterSequence: _lastSequence, pageSize: 100);
      final known = messages.map((m) => m.clientMessageId).toSet();
      final missed = page.messages.where((m) => !known.contains(m.clientMessageId)).toList();
      if (missed.isNotEmpty) {
        messages.addAll(missed);
        messages.sort((a, b) => a.sequenceNumber.compareTo(b.sequenceNumber));
        messages.refresh();
        markRead();
      }
      _trackSequence(page.messages);
    } catch (_) {
    } finally {
      _isResyncing = false;
    }
  }

  Future<void> _refreshMessage(int messageId) async {
    if (!messages.any((m) => m.id == messageId)) return;
    try {
      final fresh = await _service.getMessage(conversationId, messageId);
      final i = messages.indexWhere((m) => m.id == fresh.id);
      if (i >= 0) {
        messages[i] = fresh;
        messages.refresh();
      }
    } catch (_) {}
  }

  /// A recipient read up to [sequence]. For a 1:1 that means our messages up to there
  /// are read; for a group we can't tell from one reader, so refresh from the server
  /// where the read-by-all rule lives.
  void _applyReadWatermark(int sequence) {
    final isGroup = (detail.value?.members.length ?? 0) > 2;
    var touched = false;
    for (var i = 0; i < messages.length; i++) {
      final m = messages[i];
      if (m.senderId != currentUserId || m.sequenceNumber > sequence) continue;
      if (isGroup) {
        if (!m.isRead) _refreshMessage(m.id);
        continue;
      }
      if (!m.isRead) {
        messages[i] = m.copyWith(
          readCount: max(1, m.recipientCount),
          deliveryState: MessageReceiptState.read,
        );
        touched = true;
      }
    }
    if (touched) messages.refresh();
  }

  Future<void> _loadPresence() async {
    try {
      final list = await _service.getPresence(conversationId);
      onlineMembers
        ..clear()
        ..addAll(list.where((p) => p.isOnline).map((p) => p.caisseId));
      onlineMembers.refresh();
    } catch (_) {
      onlineMembers.clear();
    }
  }

  bool isOnline(int caisseId) => onlineMembers.contains(caisseId);

  Future<void> markRead() async {
    if (messages.isEmpty) return;
    final last = messages.lastWhere(
      (m) => m.id > 0,
      orElse: () => messages.last,
    );
    if (last.id <= 0) return;
    try {
      await _service.markRead(conversationId, last.id, last.sequenceNumber);
    } catch (_) {}
  }

  /// A RFC-4122 v4 UUID. The backend's ClientMessageId is a System.Guid, so a
  /// timestamp-based string is rejected with "could not be converted to Guid" — it
  /// must be a real UUID, exactly like the web client's crypto.randomUUID().
  String _newClientId() {
    final b = List<int>.generate(16, (_) => _rng.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40; // version 4
    b[8] = (b[8] & 0x3f) | 0x80; // variant 1
    String h(int i) => b[i].toRadixString(16).padLeft(2, '0');
    return '${h(0)}${h(1)}${h(2)}${h(3)}-${h(4)}${h(5)}-${h(6)}${h(7)}-'
        '${h(8)}${h(9)}-${h(10)}${h(11)}${h(12)}${h(13)}${h(14)}${h(15)}';
  }

  Future<void> send(String text) async {
    final body = text.trim();
    if (body.isEmpty || isSending.value) return;

    final replyToMessageId = replyingTo.value?.id;
    replyingTo.value = null;
    final clientId = _newClientId();
    final optimistic = Message(
      id: -DateTime.now().millisecondsSinceEpoch,
      conversationId: conversationId,
      sequenceNumber: 1 << 30,
      clientMessageId: clientId,
      senderId: currentUserId,
      type: MessageType.text,
      body: body,
      createdAt: DateTime.now(),
      replyToMessageId: replyToMessageId,
      pendingStatus: PendingStatus.sending,
    );
    messages.add(optimistic);
    messages.refresh();
    isSending.value = true;

    // Not connected → queue durably and show as queued. Flushed on reconnect.
    if (!_signalR.isConnected) {
      await _queue.enqueue(QueuedMessage(
        clientMessageId: clientId,
        conversationId: conversationId,
        body: body,
        replyToMessageId: replyToMessageId,
        createdAt: DateTime.now(),
      ));
      _replacePending(clientId, PendingStatus.queued);
      isSending.value = false;
      return;
    }

    try {
      final confirmed = await _service.sendMessage(
        conversationId,
        clientMessageId: clientId,
        body: body,
        replyToMessageId: replyToMessageId,
      );
      final i = messages.indexWhere((m) => m.clientMessageId == clientId);
      if (i >= 0) messages[i] = confirmed;
      _trackSequence([confirmed]);
      messages.refresh();
    } catch (_) {
      // Persist so it survives an app kill, then surface as failed/queued.
      await _queue.enqueue(QueuedMessage(
        clientMessageId: clientId,
        conversationId: conversationId,
        body: body,
        replyToMessageId: replyToMessageId,
        createdAt: DateTime.now(),
      ));
      _replacePending(clientId, PendingStatus.failed);
    } finally {
      isSending.value = false;
    }
  }

  void _replacePending(String clientId, PendingStatus status) {
    final i = messages.indexWhere((m) => m.clientMessageId == clientId);
    if (i >= 0) {
      messages[i] = messages[i].copyWith(pendingStatus: status);
      messages.refresh();
    }
  }

  void notifyTyping() => _signalR.startTyping(conversationId);

  // ── Reply / edit target ───────────────────────────────

  void startReply(Message m) {
    editing.value = null;
    replyingTo.value = m;
  }

  void cancelReply() => replyingTo.value = null;

  void startEdit(Message m) {
    replyingTo.value = null;
    editing.value = m;
  }

  void cancelEdit() => editing.value = null;

  Future<void> submitEdit(String body) async {
    final m = editing.value;
    if (m == null || body.trim().isEmpty) return;
    editing.value = null;
    try {
      final updated = await _service.editMessage(conversationId, m.id, body.trim());
      final i = messages.indexWhere((x) => x.id == m.id);
      if (i >= 0) {
        messages[i] = updated;
        messages.refresh();
      }
    } catch (_) {
      Get.snackbar('Edit failed', 'Could not edit the message',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  // ── Reactions / delete / pin ──────────────────────────

  Future<void> loadAllowedReactions() async {
    if (allowedReactions.isNotEmpty) return;
    try {
      allowedReactions.value = await _service.getAllowedReactionsEmoji();
    } catch (_) {}
  }

  Future<void> toggleReaction(int messageId, String emoji) async {
    try {
      final summary = await _service.toggleReactionOn(conversationId, messageId, emoji);
      final i = messages.indexWhere((m) => m.id == messageId);
      if (i >= 0) {
        messages[i] = messages[i].copyWithReactions(summary);
        messages.refresh();
      }
    } catch (_) {}
  }

  Future<void> deleteMessage(int messageId) async {
    try {
      await _service.deleteMessage(conversationId, messageId);
      // The realtime MessageDeleted event refreshes it; refresh eagerly too.
      _refreshMessage(messageId);
    } catch (_) {
      Get.snackbar('Delete failed', 'Could not delete the message',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> togglePin(Message m) async {
    try {
      if (m.isPinned) {
        await _service.unpinMessage(conversationId, m.id);
      } else {
        await _service.pinMessage(conversationId, m.id);
      }
      _refreshMessage(m.id);
    } catch (_) {}
  }

  // ── Mention autocomplete ──────────────────────────────

  /// Debounced suggest lookup for the composer's @-menu. [query] is the partial
  /// term after the "@" (may be empty — the "press @ before typing" case).
  void queryMentions(String query) {
    _mentionDebounce?.cancel();
    _mentionDebounce = Timer(const Duration(milliseconds: 180), () async {
      try {
        mentionSuggestions.value =
            await _service.suggestMentions(conversationId, query, limit: 8);
      } catch (_) {
        mentionSuggestions.clear();
      }
    });
  }

  void clearMentions() {
    _mentionDebounce?.cancel();
    mentionSuggestions.clear();
  }

  // ── Voice message ─────────────────────────────────────

  /// Uploads a recorded clip and sends it as a voice message.
  Future<void> sendVoice(String filePath, int durationSeconds) async {
    final clientId = _newClientId();
    final optimistic = Message(
      id: -DateTime.now().millisecondsSinceEpoch,
      conversationId: conversationId,
      sequenceNumber: 1 << 30,
      clientMessageId: clientId,
      senderId: currentUserId,
      type: MessageType.voice,
      createdAt: DateTime.now(),
      pendingStatus: PendingStatus.sending,
    );
    messages.add(optimistic);
    messages.refresh();
    try {
      final att = await _service.uploadAttachment(
        conversationId,
        filePath,
        'voice_${DateTime.now().millisecondsSinceEpoch}.m4a',
        AttachmentKind.voice,
        durationSeconds: durationSeconds,
      );
      final confirmed = await _service.sendMessage(
        conversationId,
        clientMessageId: clientId,
        attachmentIds: [att.id],
      );
      final i = messages.indexWhere((m) => m.clientMessageId == clientId);
      if (i >= 0) messages[i] = confirmed;
      _trackSequence([confirmed]);
      messages.refresh();
    } catch (_) {
      _replacePending(clientId, PendingStatus.failed);
      Get.snackbar('Voice failed', 'Could not send the voice message',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  void onClose() {
    for (final s in _subs) {
      s.cancel();
    }
    for (final t in _typingTimers.values) {
      t.cancel();
    }
    _mentionDebounce?.cancel();
    _signalR.leaveConversation(conversationId);
    // Only clear the active-conversation guard if it's still pointing at us — a fast
    // switch to another thread may have already set it to the new conversation.
    if (_root.activeConversationId == conversationId) {
      _root.setActiveConversation(null);
    }
    super.onClose();
  }
}
