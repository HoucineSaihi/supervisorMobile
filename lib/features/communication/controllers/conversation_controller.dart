import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart' show CancelToken, DioException;
import 'package:get/get.dart';

import '../models/conversation.dart';
import '../models/message.dart';
import '../services/chat_signalr_service.dart';
import '../services/mention_suggest.dart';
import '../services/messenger_local_cache.dart';
import '../services/messenger_service.dart';
import '../services/offline_queue.dart';
import 'messenger_controller.dart';

/// A just-recorded voice clip sitting in the composer, reviewed/played back and
/// possibly captioned before the user confirms the actual send.
class StagedVoice {
  final String path;
  final int durationSeconds;

  StagedVoice({required this.path, required this.durationSeconds});
}

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

  /// History is paged: the latest page on open, older pages prepended on scroll-up.
  final hasMoreOlder = false.obs;
  final isLoadingOlder = false.obs;
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

  /// A voice clip that's been recorded but not yet sent — staged in the composer so
  /// the user can review/play it back, optionally add a caption, and confirm the send
  /// explicitly (rather than the old hold-to-record-and-release-to-send flow, which
  /// gave no chance to reconsider before it was already gone).
  final stagedVoice = Rxn<StagedVoice>();

  // ── Context, pins and search ──────────────────────────

  /// Conversation-wide pinned messages. The newest is surfaced as a banner; the rest
  /// are reachable from the info screen.
  final pinnedMessages = <PinnedMessage>[].obs;

  /// Lets the user dismiss the banner for this visit without unpinning for everyone.
  final pinnedBannerDismissed = false.obs;

  /// Live status of incidents referenced by this thread, keyed by incident id, so a
  /// card can show where the incident actually stands rather than just its number.
  final incidentSummaries = <int, IncidentStatusSummary>{}.obs;

  /// Incident ids whose status fetch is in flight, so concurrent pushes for the
  /// same incident don't each issue their own request.
  final _incidentFetches = <int>{};

  /// Status of the operational object this whole conversation hangs off, when it is an
  /// incident thread. Backs the context banner under the header.
  final scopeIncident = Rxn<IncidentStatusSummary>();

  /// What this thread is about — incident, VM campaign, VM execution or mission — for
  /// the context sheet and its "Open" action. Null for DMs, groups and store channels.
  final scopeContext = Rxn<ConversationContext>();

  final searchQuery = ''.obs;
  final searchResults = <Message>[].obs;
  final isSearching = false.obs;
  final searchActive = false.obs;

  /// Unsent composer text, kept so leaving and returning does not lose it.
  String draft = '';

  // @-menu state — see queryMentions.
  Timer? _mentionDebounce;
  CancelToken? _mentionCancel;
  int _mentionSeq = 0;
  List<MentionSuggestion> _mentionMembers = const [];
  List<MentionSuggestion> _mentionEntities = const [];
  final _mentionCache = MentionSuggestCache();

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
    final cache = MessengerLocalCache.instance;

    // 1. Paint the last-seen messages from the device right away (no spinner)…
    final cached = await cache.getThread(currentUserId, conversationId);
    if (cached != null && messages.isEmpty) {
      final page = MessagePage.fromJson(cached);
      messages.value = page.messages;
      hasMoreOlder.value = page.hasMoreOlder;
      _trackSequence(page.messages);
      _mergeQueued();
      isLoading.value = false;
    }

    // 2. …then fetch everything fresh in ONE request (detail, latest page, pins,
    // presence) and let it replace the snapshot.
    try {
      final bundle = await _service.openConversation(conversationId, pageSize: 50);
      messages.value = bundle.page.messages;
      hasMoreOlder.value = bundle.page.hasMoreOlder;
      _lastSequence = 0;
      _trackSequence(bundle.page.messages);
      _mergeQueued();
      detail.value = bundle.detail;
      _loadScopeContext();
      pinnedMessages.value = bundle.pins;
      onlineMembers
        ..clear()
        ..addAll(bundle.presence.where((p) => p.isOnline).map((p) => p.caisseId));
      onlineMembers.refresh();
      isLoading.value = false;
      markRead();
      final raw = bundle.page.raw;
      if (raw != null) cache.putThread(currentUserId, conversationId, raw);
    } on DioException catch (e) {
      // Left or removed: the snapshot must not keep showing this thread.
      final status = e.response?.statusCode;
      if (status == 403 || status == 404) {
        cache.removeThread(currentUserId, conversationId);
        messages.clear();
        isLoading.value = false;
        hasError.value = true;
      } else {
        _openFailed(hadSnapshot: cached != null);
      }
    } catch (_) {
      _openFailed(hadSnapshot: cached != null);
    }
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
      // A converted message (and the system note announcing it) arrives with a
      // link but no status — resolve it now so the card fills in live.
      if (m.linkedIncidentId != null) _loadIncidentSummaries();
      if (m.senderId != currentUserId) markRead();
    }));

    _subs.add(_signalR.onResyncRequired.listen((_) => _resync()));

    _subs.add(_signalR.onThreadEvent.listen((e) {
      if (e.conversationId != conversationId) return;
      _refreshMessage(e.messageId);
    }));

    // Conversation-level changes (group renamed, members added): refetch the detail
    // so the header, info screen and member list follow without reopening.
    _subs.add(_signalR.onConversationUpdated.listen((id) {
      if (id == conversationId) refreshDetail();
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

  /// A failed refresh over a snapshot keeps the snapshot (offline reading); without
  /// one it's an error state with a retry.
  void _openFailed({required bool hadSnapshot}) {
    isLoading.value = false;
    if (!hadSnapshot) hasError.value = true;
  }

  /// Prepends the previous page. Called when the thread is scrolled near its top.
  Future<void> loadOlder() async {
    if (!hasMoreOlder.value || isLoadingOlder.value || isLoading.value) return;
    // Oldest *server* message: queued sends carry placeholder sequences and sit at the end.
    final first = messages.firstWhereOrNull((m) => m.id > 0);
    if (first == null) return;
    isLoadingOlder.value = true;
    try {
      final page = await _service.getMessages(
        conversationId,
        beforeSequence: first.sequenceNumber,
        pageSize: 50,
      );
      final known = messages.map((m) => m.clientMessageId).toSet();
      final older = page.messages.where((m) => !known.contains(m.clientMessageId)).toList();
      hasMoreOlder.value = page.hasMoreOlder;
      if (older.isNotEmpty) {
        messages.insertAll(0, older);
        _loadIncidentSummaries();
      }
    } catch (_) {
      // Leave hasMoreOlder set; the next scroll to the top retries.
    } finally {
      isLoadingOlder.value = false;
    }
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
        // A conversion may have happened during the gap this resync just closed.
        _loadIncidentSummaries();
        markRead();
      }
      _trackSequence(page.messages);
      // A gap bigger than one page: keep pulling until caught up.
      if (page.hasMoreNewer) {
        _isResyncing = false;
        await _resync();
      }
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
        if (fresh.linkedIncidentId != null) _loadIncidentSummaries();
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

  /// The thread's incident / VM campaign / execution / mission is closed: the composer
  /// gives way to a read-only bar, and editing/reacting are not offered.
  bool get isReadOnly => detail.value?.isReadOnly ?? false;

  Future<void> send(String text) async {
    final body = text.trim();
    if (body.isEmpty || isSending.value || isReadOnly) return;

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
    } catch (e) {
      if (MessengerService.isConversationClosed(e)) {
        // Closed since the thread was loaded. Not queued — it would never go through.
        _replacePending(clientId, PendingStatus.failed);
        _onClosedRejection();
        return;
      }
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
    } catch (e) {
      if (MessengerService.isConversationClosed(e)) {
        _onClosedRejection();
        return;
      }
      Get.snackbar('Edit failed', 'Could not edit the message',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  /// The server refused a write because the incident / campaign closed after this
  /// thread was loaded: say so, and refetch the detail so the composer locks now
  /// rather than on the ConversationUpdated push.
  void _onClosedRejection() {
    Get.snackbar('Discussion closed', 'This discussion is closed, so it is read-only.',
        snackPosition: SnackPosition.BOTTOM);
    refreshDetail();
  }

  // ── Reactions / delete / pin ──────────────────────────

  // ── Context, pins, search, incident linkage ───────────

  /// Resolves the conversation's own scope object: the context sheet's facts for every
  /// object type, plus the incident card details (store, assignee) for incidents.
  Future<void> _loadScopeContext() async {
    final d = detail.value;
    if (d == null || !d.hasScope) return;
    if (d.scopeStatus != null) {
      // Only objects with a lifecycle have a context; a store channel has none.
      try {
        scopeContext.value = await _service.getConversationContext(conversationId);
      } catch (_) {}
    }
    if (d.scopeType != ConversationScopeType.incident) return;
    try {
      scopeIncident.value = await _service.getIncidentStatusSummary(d.scopeId!);
    } catch (_) {}
  }

  /// Pulls status for every incident referenced by a message in view, so incident
  /// cards render live rather than as a bare id.
  ///
  /// Called on load AND whenever a message arrives carrying a link we haven't
  /// resolved yet: the server pushes the system message in real time but not the
  /// incident's status (spec C3), so without this the card stays blank until the
  /// thread is reopened.
  Future<void> _loadIncidentSummaries() async {
    final ids = messages
        .map((m) => m.linkedIncidentId)
        .whereType<int>()
        .toSet()
        .where((id) => !incidentSummaries.containsKey(id) && !_incidentFetches.contains(id))
        .toList();
    if (ids.isEmpty) return;
    // Guards against a second push for the same incident racing the first fetch.
    _incidentFetches.addAll(ids);
    for (final id in ids) {
      try {
        incidentSummaries[id] = await _service.getIncidentStatusSummary(id);
      } catch (_) {
        // Left unresolved so a later push or reopen can retry it.
      } finally {
        _incidentFetches.remove(id);
      }
    }
    incidentSummaries.refresh();
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

  /// Whether this message may be converted, and which store the incident must be
  /// declared under when the sender has no fixed one of their own.
  Future<ConvertToIncidentOptions> getConvertOptions(int messageId) {
    return _service.getConvertToIncidentOptions(conversationId, messageId);
  }

  /// Turns a message into a tracked incident. Returns the incident on success so the
  /// caller can confirm it; the server posts a system message into the thread itself.
  ///
  /// Throws on failure so the convert form can show the server's own reason
  /// (BoutiqueRequired, CanOnlyConvertOwnMessages, …) instead of a generic error.
  Future<IncidentStatusSummary> convertToIncident(
    Message m, {
    String? description,
    String? commentaire,
    int? coefId,
    int? departementId,
    int? boutiqueId,
    String? problemImageBefore,
  }) async {
    final summary = await _service.convertMessageToIncident(
      conversationId,
      m.id,
      description: description ?? m.body,
      commentaire: commentaire,
      coefId: coefId,
      departementId: departementId,
      boutiqueId: boutiqueId,
      problemImageBefore: problemImageBefore,
    );
    incidentSummaries[summary.id] = summary;
    // The conversion stamps LinkedIncidentId on the message and posts a system note.
    await _refreshMessage(m.id);
    return summary;
  }

  Future<void> loadAllowedReactions() async {
    if (allowedReactions.isNotEmpty) return;
    try {
      allowedReactions.value = await _service.getAllowedReactionsEmoji();
    } catch (_) {}
  }

  Future<void> toggleReaction(int messageId, String emoji) async {
    if (isReadOnly) return;
    try {
      final summary = await _service.toggleReactionOn(conversationId, messageId, emoji);
      final i = messages.indexWhere((m) => m.id == messageId);
      if (i >= 0) {
        messages[i] = messages[i].copyWithReactions(summary);
        messages.refresh();
      }
    } catch (e) {
      if (MessengerService.isConversationClosed(e)) _onClosedRejection();
    }
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

  /// Suggestions for the composer's @-menu. [query] is the partial term after the "@"
  /// (may be empty — the "press @ before typing" case).
  ///
  /// Members come from the detail already loaded, on the same keystroke. Entities
  /// come from the cache when possible, otherwise from one debounced request; a newer
  /// keystroke cancels the older request, and [_mentionSeq] drops any reply that
  /// still lands late, so "@a" can never overwrite "@alice".
  void queryMentions(String query) {
    final seq = ++_mentionSeq;
    _mentionDebounce?.cancel();
    _mentionCancel?.cancel();

    _mentionMembers = filterMembers(detail.value?.members, query, currentUserId);

    final cached = _mentionCache.get(query);
    if (cached != null) {
      _mentionEntities = cached;
      _renderMentions();
      return;
    }

    // Preview: narrow the longest cached prefix while the real answer is fetched.
    _mentionEntities = refineMentions(_mentionCache.longestPrefix(query) ?? _mentionEntities, query);
    _renderMentions();

    _mentionDebounce = Timer(const Duration(milliseconds: 180), () async {
      final cancel = _mentionCancel = CancelToken();
      // Until the detail loads there's no member list to filter locally.
      final excludeUsers = detail.value != null;
      try {
        final list = await _service.suggestMentions(conversationId, query,
            limit: 8, excludeUsers: excludeUsers, cancelToken: cancel);
        _mentionCache.set(query, list);
        if (seq != _mentionSeq) return;
        _mentionEntities = list;
      } catch (_) {
        if (seq != _mentionSeq) return;
        _mentionEntities = const [];
      }
      _renderMentions();
    });
  }

  // ── Group name & membership ───────────────────────────

  Future<void> refreshDetail() async {
    try {
      detail.value = await _service.getConversation(conversationId);
      // Its incident / campaign may have opened or closed (that's what triggers most
      // ConversationUpdated pushes on a scoped thread): keep the context in step.
      _loadScopeContext();
    } catch (_) {
      // Keep what we have; the next open or update will catch up.
    }
  }

  /// Plain groups only — a 1:1 shows the other person, and channels/context threads
  /// are named after their store, incident or campaign (the server enforces it too).
  bool get canRename {
    final d = detail.value;
    return d != null && d.type == ConversationType.group && d.scopeType == ConversationScopeType.none;
  }

  /// Renames the group; throws on failure so the dialog can say so.
  Future<void> rename(String title) async {
    detail.value = await _service.renameConversation(conversationId, title.trim());
    _root.loadConversations(silent: true);
  }

  /// Adds people to this group in place. Returns the updated detail.
  Future<ConversationDetail> addMembers(List<int> ids) async {
    final updated = await _service.addMembers(conversationId, ids);
    detail.value = updated;
    _root.loadConversations(silent: true);
    return updated;
  }

  /// Widens a 1:1 into a NEW named group with the other person plus [ids]; the
  /// direct thread stays private and untouched. Returns the new group.
  Future<ConversationDetail> createGroupFromDirect(String title, List<int> ids) async {
    final counterpart = detail.value?.members
        .where((m) => m.caisseId != currentUserId)
        .map((m) => m.caisseId)
        .toList() ?? const <int>[];
    final created = await _service.createGroupConversation(title.trim(), [...counterpart, ...ids]);
    _root.loadConversations(silent: true);
    return created;
  }

  /// Search for the "@" button's picker, scoped to one [type] ('User', 'Incident',
  /// 'Mission', 'Boutique', 'Campaign'). People come from the loaded member list with
  /// no request; everything else from the server, up to 20.
  Future<List<MentionSuggestion>> searchMentions(String type, String query,
      {CancelToken? cancelToken}) async {
    final members = detail.value?.members;
    if (type == 'User' && members != null) {
      return filterMembers(members, query, currentUserId, max: 50);
    }
    return _service.suggestMentions(conversationId, query,
        entityType: type, limit: 20, cancelToken: cancelToken);
  }

  /// Members first, then entities; a user the server also returned is shown once.
  void _renderMentions() {
    final seen = <String>{};
    mentionSuggestions.value = [..._mentionMembers, ..._mentionEntities]
        .where((s) => seen.add('${s.entityType}:${s.entityId}'))
        .toList();
  }

  void clearMentions() {
    _mentionSeq++;
    _mentionDebounce?.cancel();
    _mentionCancel?.cancel();
    _mentionMembers = const [];
    _mentionEntities = const [];
    mentionSuggestions.clear();
  }

  // ── Attachments (voice / image / file) ────────────────

  /// Uploads a recorded clip and sends it as a voice message, with an optional
  /// caption typed alongside it while it sat staged in the composer.
  Future<void> sendVoice(String filePath, int durationSeconds, {String? caption}) {
    return _sendAttachment(
      filePath: filePath,
      fileName: 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a',
      kind: AttachmentKind.voice,
      optimisticType: MessageType.voice,
      durationSeconds: durationSeconds,
      body: caption,
      failureMessage: 'Could not send the voice message',
    );
  }

  /// Discards a staged-but-unsent recording (the delete/X on its preview chip).
  void discardStagedVoice() {
    final staged = stagedVoice.value;
    stagedVoice.value = null;
    if (staged != null) {
      final f = File(staged.path);
      f.exists().then((exists) {
        if (exists) f.delete();
      });
    }
  }

  /// Uploads a picked photo (camera or gallery) and sends it as an image message.
  /// [isAnnotated] marks a photo flattened by the markup screen.
  Future<void> sendImage(String filePath, String fileName,
      {String? caption, bool isAnnotated = false, int? width, int? height}) {
    return _sendAttachment(
      filePath: filePath,
      fileName: fileName,
      kind: AttachmentKind.image,
      optimisticType: MessageType.image,
      body: caption,
      failureMessage: 'Could not send the image',
      isAnnotated: isAnnotated,
      width: width,
      height: height,
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
    bool isAnnotated = false,
    int? width,
    int? height,
  }) async {
    if (isReadOnly) return;
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
      // Voice needs to be playable the instant it's recorded — waiting for the
      // upload+send round-trip to finish left the bubble with nothing to render in
      // the meantime. Image/file previews don't have this gap in the same way (a
      // thumbnail isn't needed to confirm "I sent the right thing" the way hearing
      // the clip back is), so this stays voice-only for now.
      attachments: kind == AttachmentKind.voice
          ? [
              MessageAttachment(
                id: -DateTime.now().millisecondsSinceEpoch,
                kind: kind,
                url: '',
                fileName: fileName,
                // Unused for playback here: VoicePlayer only consults contentType to
                // pick a decoder extension when downloading from the server, and skips
                // that whole path when localFilePath is set (it hands the recorded
                // file straight to the player as-is).
                contentType: 'application/octet-stream',
                sizeBytes: 0,
                durationSeconds: durationSeconds,
                localFilePath: filePath,
              ),
            ]
          : const [],
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
        isAnnotated: isAnnotated,
        width: width,
        height: height,
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
    } catch (e) {
      _replacePending(clientId, PendingStatus.failed);
      if (MessengerService.isConversationClosed(e)) {
        _onClosedRejection();
      } else {
        Get.snackbar('Send failed', failureMessage, snackPosition: SnackPosition.BOTTOM);
      }
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
    _mentionCancel?.cancel();
    // A recording staged but never sent (user left the thread instead) has nothing
    // else that will ever clean up its temp file.
    discardStagedVoice();
    _signalR.leaveConversation(conversationId);
    // Only clear the active-conversation guard if it's still pointing at us — a fast
    // switch to another thread may have already set it to the new conversation.
    if (_root.activeConversationId == conversationId) {
      _root.setActiveConversation(null);
    }
    super.onClose();
  }
}
