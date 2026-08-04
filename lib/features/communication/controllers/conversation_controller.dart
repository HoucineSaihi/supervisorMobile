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

  // ── Context, pins and search ──────────────────────────

  /// Conversation-wide pinned messages. The newest is surfaced as a banner; the rest
  /// are reachable from the info screen.
  final pinnedMessages = <PinnedMessage>[].obs;

  /// Lets the user dismiss the banner for this visit without unpinning for everyone.
  final pinnedBannerDismissed = false.obs;

  /// Live status of incidents referenced by this thread, keyed by incident id, so a
  /// card can show where the incident actually stands rather than just its number.
  final incidentSummaries = <int, IncidentStatusSummary>{}.obs;

  /// Status of the operational object this whole conversation hangs off, when it is an
  /// incident thread. Backs the context banner under the header.
  final scopeIncident = Rxn<IncidentStatusSummary>();

  final searchQuery = ''.obs;
  final searchResults = <Message>[].obs;
  final isSearching = false.obs;
  final searchActive = false.obs;

  /// Unsent composer text, kept so leaving and returning does not lose it.
  String draft = '';
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

  /// Retries the initial load after a failure.
  Future<void> reload() => _open();

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
      _loadScopeContext();
    } catch (_) {}
    loadPinnedMessages();
    _loadIncidentSummaries();
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

  // ── Context, pins, search, incident linkage ───────────

  /// Resolves the conversation's own scope object. Only incidents have a status
  /// endpoint today; other scope types render from the badge alone.
  Future<void> _loadScopeContext() async {
    final d = detail.value;
    if (d == null || !d.hasScope) return;
    if (d.scopeType != ConversationScopeType.incident) return;
    try {
      scopeIncident.value = await _service.getIncidentStatusSummary(d.scopeId!);
    } catch (_) {}
  }

  /// Pulls status for every incident referenced by a message in view, so incident
  /// cards render live rather than as a bare id.
  Future<void> _loadIncidentSummaries() async {
    final ids = messages
        .map((m) => m.linkedIncidentId)
        .whereType<int>()
        .toSet()
        .where((id) => !incidentSummaries.containsKey(id))
        .toList();
    if (ids.isEmpty) return;
    for (final id in ids) {
      try {
        incidentSummaries[id] = await _service.getIncidentStatusSummary(id);
      } catch (_) {}
    }
  }

  Future<void> loadPinnedMessages() async {
    try {
      pinnedMessages.value = await _service.getPinnedMessages(conversationId);
    } catch (_) {}
  }

  void openSearch() => searchActive.value = true;

  void closeSearch() {
    searchActive.value = false;
    searchQuery.value = '';
    searchResults.clear();
  }

  /// In-thread search over the full history — not just what is currently loaded.
  Future<void> runSearch(String query) async {
    searchQuery.value = query;
    final q = query.trim();
    // The server rejects anything shorter, so don't spend a request on it.
    if (q.length < 2) {
      searchResults.clear();
      isSearching.value = false;
      return;
    }
    isSearching.value = true;
    try {
      final page = await _service.searchMessages(conversationId, q);
      // Guard against an earlier request landing after a later one.
      if (searchQuery.value.trim() == q) {
        searchResults.value = page.messages;
      }
    } catch (_) {
      searchResults.clear();
    } finally {
      isSearching.value = false;
    }
  }

  /// Turns a message into a tracked incident. Returns the incident on success so the
  /// caller can confirm it; the server posts a system message into the thread itself.
  Future<IncidentStatusSummary?> convertToIncident(Message m, {String? description}) async {
    try {
      final summary = await _service.convertMessageToIncident(
        conversationId,
        m.id,
        description: description ?? m.body,
      );
      incidentSummaries[summary.id] = summary;
      // The conversion stamps LinkedIncidentId on the message and posts a system note.
      await _refreshMessage(m.id);
      return summary;
    } catch (_) {
      return null;
    }
  }

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
      // Keep the pinned banner in step with the change we just made.
      loadPinnedMessages();
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

  // ── Attachments (voice / image / file) ────────────────

  /// Uploads a recorded clip and sends it as a voice message.
  Future<void> sendVoice(String filePath, int durationSeconds) {
    return _sendAttachment(
      filePath: filePath,
      fileName: 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a',
      kind: AttachmentKind.voice,
      optimisticType: MessageType.voice,
      durationSeconds: durationSeconds,
      failureMessage: 'Could not send the voice message',
    );
  }

  /// Uploads a picked photo (camera or gallery) and sends it as an image message.
  Future<void> sendImage(String filePath, String fileName, {String? caption}) {
    return _sendAttachment(
      filePath: filePath,
      fileName: fileName,
      kind: AttachmentKind.image,
      optimisticType: MessageType.image,
      body: caption,
      failureMessage: 'Could not send the image',
    );
  }

  /// Uploads an arbitrary document and sends it as a file message.
  Future<void> sendFile(String filePath, String fileName, {String? caption}) {
    return _sendAttachment(
      filePath: filePath,
      fileName: fileName,
      kind: AttachmentKind.file,
      optimisticType: MessageType.file,
      body: caption,
      failureMessage: 'Could not send the file',
    );
  }

  /// Shared upload-then-send path for every attachment kind.
  ///
  /// Attachments are deliberately NOT put through the offline outbox: the queue
  /// persists only body text, and the staged upload it would reference is swept
  /// server-side, so a queued media send could never be replayed faithfully. A
  /// failed media send is surfaced as failed instead of silently pending.
  Future<void> _sendAttachment({
    required String filePath,
    required String fileName,
    required AttachmentKind kind,
    required MessageType optimisticType,
    required String failureMessage,
    String? body,
    int? durationSeconds,
  }) async {
    final replyToMessageId = replyingTo.value?.id;
    replyingTo.value = null;

    final clientId = _newClientId();
    final optimistic = Message(
      id: -DateTime.now().millisecondsSinceEpoch,
      conversationId: conversationId,
      sequenceNumber: 1 << 30,
      clientMessageId: clientId,
      senderId: currentUserId,
      type: optimisticType,
      body: body,
      createdAt: DateTime.now(),
      replyToMessageId: replyToMessageId,
      pendingStatus: PendingStatus.sending,
    );
    messages.add(optimistic);
    messages.refresh();
    isSending.value = true;

    try {
      final att = await _service.uploadAttachment(
        conversationId,
        filePath,
        fileName,
        kind,
        durationSeconds: durationSeconds,
      );
      final confirmed = await _service.sendMessage(
        conversationId,
        clientMessageId: clientId,
        body: body,
        replyToMessageId: replyToMessageId,
        attachmentIds: [att.id],
      );
      final i = messages.indexWhere((m) => m.clientMessageId == clientId);
      if (i >= 0) messages[i] = confirmed;
      _trackSequence([confirmed]);
      messages.refresh();
    } catch (_) {
      _replacePending(clientId, PendingStatus.failed);
      Get.snackbar('Send failed', failureMessage, snackPosition: SnackPosition.BOTTOM);
    } finally {
      isSending.value = false;
    }
  }

  /// Per-person read breakdown for one of my messages, for the "seen by" popup.
  Future<MessageReceipts> loadReceipts(int messageId) =>
      _service.getReceipts(conversationId, messageId);

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
