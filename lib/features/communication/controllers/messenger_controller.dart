import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import '../models/conversation.dart';
import '../models/message.dart';
import '../services/chat_signalr_service.dart';
import '../services/media_cache.dart';
import '../services/messenger_local_cache.dart';
import '../services/messenger_service.dart';
import '../services/offline_queue.dart';

/// Inbox filter chips. Mirrors the web module's chip set, minus Direct — the mobile
/// spec asks for Mentions instead, which the server now flags per conversation.
/// Closed = threads whose incident / VM campaign / execution / mission is closed.
enum ConversationFilter { all, unread, mentions, groups, closed }

extension ConversationFilterLabel on ConversationFilter {
  String get label {
    switch (this) {
      case ConversationFilter.all:
        return 'All';
      case ConversationFilter.unread:
        return 'Unread';
      case ConversationFilter.mentions:
        return 'Mentions';
      case ConversationFilter.groups:
        return 'Groups';
      case ConversationFilter.closed:
        return 'Closed';
    }
  }
}

/// App-level messenger state: the conversation list, the shared SignalR connection,
/// and the offline outbox flush. Lives as long as the messenger tab is mounted.
class MessengerController extends GetxController with WidgetsBindingObserver {
  final MessengerService service = MessengerService();
  final ChatSignalRService signalR = ChatSignalRService();
  final OfflineQueue queue = OfflineQueue();

  /// Loaded inbox rows. Search and the filter chip run server-side, so this is always
  /// the first N pages of the answer — never a client-side subset of one page.
  final conversations = <ConversationSummary>[].obs;
  final isLoading = false.obs;
  final hasError = false.obs;

  // ── Paging ────────────────────────────────────────────
  final hasMore = false.obs;
  final isLoadingMore = false.obs;
  /// Server totals for the chips (all conversations, not just loaded pages).
  final counts = const ConversationCounts().obs;
  String? _nextCursor;
  /// Bumped per first-page request so a slow, superseded response is dropped.
  int _listRequest = 0;
  Timer? _searchDebounce;
  static const int _pageSize = 30;
  final connection = ConnectionStatus.connecting.obs;
  final pendingOutbox = 0.obs;

  // ── Inbox view state ──────────────────────────────────
  // Lives on the controller rather than the screen because this controller is
  // `permanent: true` while the screen widget is rebuilt from scratch on every tab
  // switch — keeping it here is what makes the filter/search survive leaving the tab.

  final filter = ConversationFilter.all.obs;
  final searchQuery = ''.obs;

  /// Collapses the pinned block to a short preview. Cosmetic, so it is not persisted.
  final pinnedExpanded = true.obs;

  /// Unread notification total, kept live by hub pushes and primed/backstopped over
  /// REST. Drives the badge on the Messages nav destination.
  final unreadNotifications = 0.obs;

  /// Emits notifications that warrant a visible toast (i.e. the user isn't already
  /// reading that conversation). A global overlay listens and renders them.
  final _toast = StreamController<AppNotification>.broadcast();
  Stream<AppNotification> get onToast => _toast.stream;

  int currentUserId = 0;

  /// Conversation the user is currently reading, if any. Set by the conversation
  /// screen on open and cleared on close — suppresses a redundant toast for the
  /// thread that's already on screen (mirrors the Angular NotificationService rule).
  int? activeConversationId;

  final _storage = const FlutterSecureStorage();
  StreamSubscription? _statusSub;
  StreamSubscription? _messageSub;
  StreamSubscription? _convUpdatedSub;
  StreamSubscription? _convAddedSub;
  StreamSubscription? _resyncSub;
  StreamSubscription? _notificationSub;
  StreamSubscription? _notificationCountSub;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  /// Tears down every trace of the signed-in user: the live hub (which is
  /// authenticated as the *old* account and would keep pushing their messages),
  /// the cached conversation list, the badge, and the offline outbox.
  ///
  /// Must run on logout and on 401 session expiry. Without it, this controller is
  /// `permanent: true` and survives into the next session, so the next user opens
  /// the messenger onto the previous user's threads.
  Future<void> resetForLogout() async {
    _statusSub?.cancel();
    _messageSub?.cancel();
    _convUpdatedSub?.cancel();
    _convAddedSub?.cancel();
    _resyncSub?.cancel();
    _notificationSub?.cancel();
    _notificationCountSub?.cancel();
    _searchDebounce?.cancel();
    _statusSub = null;
    _messageSub = null;
    _convUpdatedSub = null;
    _convAddedSub = null;
    _resyncSub = null;
    _notificationSub = null;
    _notificationCountSub = null;

    await signalR.disconnect();

    // Cached media and snapshots belong to the old account too.
    await MediaCache.instance.clear();
    await MessengerLocalCache.instance.clear();

    // Queued sends belong to the old account — delivering them under the next
    // user's token would post as the wrong person.
    try {
      await queue.clear();
    } catch (_) {}

    currentUserId = 0;
    activeConversationId = null;
    conversations.clear();
    hasMore.value = false;
    isLoadingMore.value = false;
    counts.value = const ConversationCounts();
    _nextCursor = null;
    unreadNotifications.value = 0;
    pendingOutbox.value = 0;
    isLoading.value = false;
    hasError.value = false;
    connection.value = ConnectionStatus.connecting;

    // Inbox view state is per-user too — a filter or search left over from the previous
    // account would silently hide the new user's conversations.
    filter.value = ConversationFilter.all;
    searchQuery.value = '';
    pinnedExpanded.value = true;
  }

  /// Re-runs bootstrap for a newly signed-in account. Pairs with [resetForLogout]
  /// so the permanent controller can be reused across sessions.
  Future<void> reinitializeForNewUser() => _bootstrap();

  Future<void> _bootstrap() async {
    final id = await _storage.read(key: 'currentUserId');
    currentUserId = int.tryParse(id ?? '') ?? 0;

    // No credentials yet (cold start before login, or just after a logout) — stay
    // idle rather than firing an unauthenticated load that would 401 and trip the
    // session-expiry handler.
    if (currentUserId == 0) return;

    _statusSub = signalR.onStatus.listen((s) {
      connection.value = s;
      if (s == ConnectionStatus.connected) {
        flushOutbox();
      }
    });
    // Instant inbox update straight from the push payload — no REST round-trip.
    // ConversationUpdated (below) still exists as a self-healing backstop for
    // whatever this local patch can't derive (e.g. another member's mute/pin change),
    // but it must NOT fire a full reload on every single message or the "real-time"
    // chat would cost a list refetch per message, defeating the point of the push.
    _messageSub = signalR.onMessage.listen(_onMessageReceived);
    // Row-level refresh: fetch just the affected conversation, never the whole inbox.
    _convUpdatedSub = signalR.onConversationUpdated.listen(refreshRow);
    _convAddedSub = signalR.onConversationAdded.listen(refreshRow);
    _resyncSub = signalR.onResyncRequired.listen((_) {
      loadConversations(silent: true);
      // A gap in the live feed may have dropped a Notification push — re-prime the
      // badge from REST so it self-heals instead of staying stale.
      refreshUnreadNotifications();
    });

    // Global notification handling: bump the badge and raise a toast on every screen,
    // not only while the messenger is open. This is the piece that makes a message
    // sent to a user on another tab actually surface.
    _notificationSub = signalR.onNotification.listen(_onNotification);
    _notificationCountSub =
        signalR.onNotificationCount.listen((count) => unreadNotifications.value = count);

    // Cold start: paint the last-known inbox from the device, then refresh silently.
    final cached = await MessengerLocalCache.instance.getInbox(currentUserId);
    if (cached != null && conversations.isEmpty) {
      final snapshot = ConversationListResponse.fromJson(cached);
      conversations.value = snapshot.conversations;
      if (snapshot.counts != null) counts.value = snapshot.counts!;
    }
    await loadConversations(silent: conversations.isNotEmpty);
    _refreshOutboxCount();
    refreshUnreadNotifications();
    signalR.connect().catchError((_) {});
  }

  /// Patches the affected conversation row straight from the pushed message — no
  /// REST call. Covers the common case (preview text, sender, timestamp, reordering
  /// to the top, an approximate unread bump/urgency dot); anything this can't derive
  /// self-heals the next time a full list load happens anyway (app foreground,
  /// pull-to-refresh, or the onResyncRequired gap-fill).
  void _onMessageReceived(Message m) {
    final i = conversations.indexWhere((c) => c.id == m.conversationId);
    if (i < 0) {
      // Not on a loaded page (an older thread, or a brand-new one): fetch that one
      // row rather than reloading every page.
      refreshRow(m.conversationId);
      return;
    }

    final isOwnMessage = m.senderId == currentUserId;
    final isViewingThisConversation = m.conversationId == activeConversationId;
    final current = conversations[i];

    // Mirrors MessagePriorityRules.PiercesMute on the backend — keep in sync if that
    // ever changes. Approximate on purpose: the exact mention/mute interplay is
    // still resolved server-side and will correct itself on the next full refresh.
    final piercesMute = m.priority == MessagePriority.urgent || m.priority == MessagePriority.critical;
    final isMentioned = m.body != null && m.body!.contains('@[User:$currentUserId]');
    final countsAsUnread = !isOwnMessage &&
        !isViewingThisConversation &&
        (!current.isMuted || piercesMute || isMentioned);

    final updated = current.copyWith(
      lastMessagePreview: _previewFor(m),
      lastMessageSenderName: m.senderName,
      lastMessageAt: m.createdAt,
      lastMessageId: m.id,
      lastMessageSequence: m.sequenceNumber,
      unreadCount: countsAsUnread ? current.unreadCount + 1 : null,
      highestUnreadPriority: countsAsUnread && m.priority != MessagePriority.normal
          ? m.priority
          : null,
      hasUnreadMention: countsAsUnread && isMentioned ? true : null,
    );

    if (countsAsUnread && current.unreadCount == 0) {
      counts.value = _withUnreadDelta(counts.value, 1);
    }
    conversations[i] = updated;
    _resort();
  }

  /// Server order, kept locally after in-place patches: pinned first, then latest.
  void _resort() {
    final sorted = [...conversations]..sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        final at = a.lastMessageAt?.millisecondsSinceEpoch ?? 0;
        final bt = b.lastMessageAt?.millisecondsSinceEpoch ?? 0;
        return bt != at ? bt.compareTo(at) : b.id.compareTo(a.id);
      });
    conversations.value = sorted;
  }

  static ConversationCounts _withUnreadDelta(ConversationCounts c, int delta) => ConversationCounts(
        all: c.all,
        unread: (c.unread + delta).clamp(0, 1 << 30),
        direct: c.direct,
        groups: c.groups,
        mentions: c.mentions,
        closed: c.closed,
      );

  static ConversationCounts _withClosedDelta(ConversationCounts c, int delta) => ConversationCounts(
        all: c.all,
        unread: c.unread,
        direct: c.direct,
        groups: c.groups,
        mentions: c.mentions,
        closed: (c.closed + delta).clamp(0, 1 << 30),
      );

  /// Fetches one row and inserts or replaces it. A 404 (left / removed) drops it.
  ///
  /// This is also how a thread follows its incident / campaign: the server sends
  /// ConversationUpdated when the object opens or closes, and the fresh row carries
  /// the new status pill.
  Future<void> refreshRow(int conversationId) async {
    try {
      final summary = await service.getConversationSummary(conversationId);
      final i = conversations.indexWhere((c) => c.id == conversationId);
      if (i >= 0) {
        if (conversations[i].isClosed != summary.isClosed) {
          counts.value = _withClosedDelta(counts.value, summary.isClosed ? 1 : -1);
        }
        conversations[i] = summary;
      } else if (_matchesActiveFilter(summary)) {
        conversations.insert(0, summary);
      }
      _resort();
    } catch (_) {
      conversations.removeWhere((c) => c.id == conversationId);
    }
  }

  /// Approximates the server filter for rows that arrive outside of paging.
  bool _matchesActiveFilter(ConversationSummary c) {
    switch (filter.value) {
      case ConversationFilter.unread:
        return c.unreadCount > 0;
      case ConversationFilter.mentions:
        return c.hasUnreadMention;
      case ConversationFilter.groups:
        return c.type == ConversationType.group || c.type == ConversationType.channel;
      case ConversationFilter.closed:
        return c.isClosed;
      case ConversationFilter.all:
        break;
    }
    final q = searchQuery.value.trim().toLowerCase();
    return q.isEmpty || (c.title ?? '').toLowerCase().contains(q);
  }

  static String? _filterParam(ConversationFilter f) {
    switch (f) {
      case ConversationFilter.unread:
        return 'unread';
      case ConversationFilter.mentions:
        return 'mentions';
      case ConversationFilter.groups:
        return 'groups';
      case ConversationFilter.closed:
        return 'closed';
      case ConversationFilter.all:
        return null;
    }
  }

  static String _previewFor(Message m) {
    switch (m.type) {
      case MessageType.image:
        return '📷 Photo';
      case MessageType.voice:
        return '🎤 Voice message';
      case MessageType.file:
        return '📎 File';
      default:
        return m.body ?? '';
    }
  }

  void _onNotification(NotificationEvent e) {
    unreadNotifications.value = e.unreadCount;
    // The list preview/unread counts are bumped straight from onMessage; here we
    // only decide how to present. Suppress the toast when the user is already reading
    // that exact conversation — the message is right there — but still play a subtle
    // cue. Mirrors the web NotificationService's sound-only vs toast rule.
    final n = e.notification;
    final isViewingThisConversation =
        n.conversationId != null && n.conversationId == activeConversationId;

    if (isViewingThisConversation) {
      _alert(subtle: true);
      return;
    }
    _alert(subtle: false);
    if (!_toast.isClosed) _toast.add(n);
  }

  /// Audible + haptic cue for an incoming notification, on any screen. Uses the
  /// platform sounds already available to Flutter so no audio asset or extra plugin
  /// is needed. Never throws — an alert is a nicety, not a delivery guarantee.
  void _alert({required bool subtle}) {
    try {
      // A quieter click when you're already in the thread; the fuller alert tone
      // otherwise. Haptic is softened the same way.
      SystemSound.play(subtle ? SystemSoundType.click : SystemSoundType.alert);
      if (subtle) {
        HapticFeedback.selectionClick();
      } else {
        HapticFeedback.mediumImpact();
      }
    } catch (_) {}
  }

  /// Primes/backstops the unread badge from REST. Safe to call on startup and after
  /// any realtime gap. Silent on failure — the live push keeps it current in steady state.
  Future<void> refreshUnreadNotifications() async {
    try {
      unreadNotifications.value = await service.getUnreadNotificationCount();
    } catch (_) {}
  }

  void setActiveConversation(int? conversationId) {
    activeConversationId = conversationId;
  }

  /// (Re)loads the first page for the current search + chip. [silent] keeps the rows
  /// on screen (background resync) instead of showing the skeleton.
  Future<void> loadConversations({bool silent = false}) async {
    final request = ++_listRequest;
    if (!silent || conversations.isEmpty) isLoading.value = true;
    hasError.value = false;
    try {
      final res = await service.getConversations(
        search: searchQuery.value,
        filter: _filterParam(filter.value),
        pageSize: _pageSize,
      );
      if (request != _listRequest) return; // superseded by a newer search/filter
      conversations.value = res.conversations;
      _nextCursor = res.nextCursor;
      hasMore.value = res.hasMore && res.nextCursor != null;
      if (res.counts != null) counts.value = res.counts!;
      // Only the plain inbox is worth a cold-start snapshot, not a filtered view.
      final raw = res.raw;
      if (raw != null && filter.value == ConversationFilter.all && searchQuery.value.trim().isEmpty) {
        MessengerLocalCache.instance.putInbox(currentUserId, raw);
      }
    } catch (_) {
      if (request == _listRequest && !silent) hasError.value = true;
    } finally {
      if (request == _listRequest) isLoading.value = false;
    }
  }

  /// Next page — called when the inbox scrolls near its end.
  Future<void> loadMore() async {
    final cursor = _nextCursor;
    if (!hasMore.value || cursor == null || isLoadingMore.value || isLoading.value) return;
    final request = _listRequest;
    isLoadingMore.value = true;
    try {
      final res = await service.getConversations(
        cursor: cursor,
        search: searchQuery.value,
        filter: _filterParam(filter.value),
        pageSize: _pageSize,
      );
      if (request != _listRequest) return; // a reset happened meanwhile
      final known = conversations.map((c) => c.id).toSet();
      conversations.addAll(res.conversations.where((c) => !known.contains(c.id)));
      _nextCursor = res.nextCursor;
      hasMore.value = res.hasMore && res.nextCursor != null;
    } catch (_) {
      // Leave hasMore set: the next scroll retries.
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// Delivers queued messages once connectivity returns. At-least-once is safe: the
  /// server dedupes on clientMessageId.
  Future<void> flushOutbox() async {
    final items = await queue.pending();
    for (final m in items) {
      try {
        await service.sendMessage(
          m.conversationId,
          clientMessageId: m.clientMessageId,
          body: m.body,
          replyToMessageId: m.replyToMessageId,
        );
        await queue.remove(m.clientMessageId);
      } catch (e) {
        if (MessengerService.isConversationClosed(e)) {
          // The incident / campaign closed while this sat in the outbox. A permanent
          // refusal — retrying would fail on every reconnect forever.
          await queue.remove(m.clientMessageId);
          continue;
        }
        await queue.markAttempt(m.clientMessageId);
        // Leave it queued; the next connectivity event retries.
      }
    }
    _refreshOutboxCount();
  }

  Future<void> _refreshOutboxCount() async {
    pendingOutbox.value = await queue.count();
  }

  /// Clears a conversation's unread badge locally once it's opened.
  ///
  /// Local-only on purpose: the thread screen's own controller already reports the read
  /// watermark to the server when it opens, so syncing here too would double the call.
  /// Use [markReadFromInbox] for the list's own mark-read action, which has no thread
  /// controller to do it.
  void markConversationRead(int conversationId) {
    final i = conversations.indexWhere((c) => c.id == conversationId);
    if (i >= 0 && conversations[i].unreadCount > 0) {
      counts.value = _withUnreadDelta(counts.value, -1);
      conversations[i] = conversations[i].copyWith(
        unreadCount: 0,
        clearUnreadPriority: true,
        hasUnreadMention: false,
      );
      conversations.refresh();
    }
  }

  // ── Inbox actions ─────────────────────────────────────

  void setFilter(ConversationFilter f) {
    if (filter.value == f) return;
    filter.value = f;
    loadConversations();
  }

  /// Debounced: the query runs server-side, so don't fire a request per keystroke.
  void setSearchQuery(String q) {
    searchQuery.value = q;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), loadConversations);
  }

  void clearFilters() {
    _searchDebounce?.cancel();
    filter.value = ConversationFilter.all;
    searchQuery.value = '';
    loadConversations();
  }

  /// The loaded rows. Search and the chip are applied by the server, so no second
  /// client-side pass — which would also wrongly hide DMs matched by the other
  /// person's name.
  List<ConversationSummary> get filteredConversations => conversations;

  List<ConversationSummary> get pinnedConversations =>
      filteredConversations.where((c) => c.isPinned).toList();

  List<ConversationSummary> get unpinnedConversations =>
      filteredConversations.where((c) => !c.isPinned).toList();

  /// Marks read from the list itself — clears the badge immediately, then reports the
  /// watermark. Silent on failure; the next load reconciles from the server.
  Future<void> markReadFromInbox(int conversationId) async {
    final i = conversations.indexWhere((c) => c.id == conversationId);
    if (i < 0 || conversations[i].unreadCount == 0) return;
    final conv = conversations[i];

    markConversationRead(conversationId);

    final msgId = conv.lastMessageId;
    final seq = conv.lastMessageSequence;
    if (msgId == null || seq == null) return; // nothing to report yet
    try {
      await service.markRead(conversationId, msgId, seq);
      refreshUnreadNotifications();
    } catch (_) {}
  }

  /// Pin/unpin, applied locally first and rolled back if the server rejects it.
  Future<void> togglePin(int conversationId) async {
    final i = conversations.indexWhere((c) => c.id == conversationId);
    if (i < 0) return;
    final next = !conversations[i].isPinned;

    conversations[i] = conversations[i].copyWith(isPinned: next);
    _resort(); // lands in the right section locally; no reload of every page
    try {
      await service.setConversationPinned(conversationId, next);
    } catch (_) {
      final j = conversations.indexWhere((c) => c.id == conversationId);
      if (j >= 0) {
        conversations[j] = conversations[j].copyWith(isPinned: !next);
        _resort();
      }
    }
  }

  /// Mutes until [until], or unmutes when it is null. Optimistic with rollback.
  Future<void> toggleMute(int conversationId, {DateTime? until}) async {
    final i = conversations.indexWhere((c) => c.id == conversationId);
    if (i < 0) return;
    final prev = conversations[i];

    conversations[i] = prev.copyWith(
      isMuted: until != null,
      mutedUntil: until,
      clearMutedUntil: until == null,
    );
    conversations.refresh();
    try {
      await service.setConversationMuted(conversationId, until);
    } catch (_) {
      final j = conversations.indexWhere((c) => c.id == conversationId);
      if (j >= 0) {
        conversations[j] = conversations[j].copyWith(
          isMuted: prev.isMuted,
          mutedUntil: prev.mutedUntil,
          clearMutedUntil: prev.mutedUntil == null,
        );
        conversations.refresh();
      }
    }
  }

  /// Leaves a group/channel and drops it from the list on success.
  Future<bool> leaveConversation(int conversationId) async {
    try {
      await service.leaveConversation(conversationId);
      conversations.removeWhere((c) => c.id == conversationId);
      conversations.refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      signalR.wakeUp();
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _statusSub?.cancel();
    _messageSub?.cancel();
    _convUpdatedSub?.cancel();
    _convAddedSub?.cancel();
    _searchDebounce?.cancel();
    _resyncSub?.cancel();
    _notificationSub?.cancel();
    _notificationCountSub?.cancel();
    _toast.close();
    signalR.disconnect();
    super.onClose();
  }
}
