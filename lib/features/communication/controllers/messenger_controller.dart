import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import '../models/conversation.dart';
import '../services/chat_signalr_service.dart';
import '../services/messenger_service.dart';
import '../services/offline_queue.dart';

/// Inbox filter chips. Mirrors the web module's chip set, minus Direct — the mobile
/// spec asks for Mentions instead, which the server now flags per conversation.
enum ConversationFilter { all, unread, mentions, groups }

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
    }
  }
}

/// App-level messenger state: the conversation list, the shared SignalR connection,
/// and the offline outbox flush. Lives as long as the messenger tab is mounted.
class MessengerController extends GetxController with WidgetsBindingObserver {
  final MessengerService service = MessengerService();
  final ChatSignalRService signalR = ChatSignalRService();
  final OfflineQueue queue = OfflineQueue();

  final conversations = <ConversationSummary>[].obs;
  final isLoading = false.obs;
  final hasError = false.obs;
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
  StreamSubscription? _convUpdatedSub;
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
    _convUpdatedSub?.cancel();
    _resyncSub?.cancel();
    _notificationSub?.cancel();
    _notificationCountSub?.cancel();
    _statusSub = null;
    _convUpdatedSub = null;
    _resyncSub = null;
    _notificationSub = null;
    _notificationCountSub = null;

    await signalR.disconnect();

    // Queued sends belong to the old account — delivering them under the next
    // user's token would post as the wrong person.
    try {
      await queue.clear();
    } catch (_) {}

    currentUserId = 0;
    activeConversationId = null;
    conversations.clear();
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
    // The list's unread counts and previews go stale across a gap, exactly like an
    // open thread does.
    _convUpdatedSub = signalR.onConversationUpdated.listen((_) => loadConversations(silent: true));
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

    await loadConversations();
    _refreshOutboxCount();
    refreshUnreadNotifications();
    signalR.connect().catchError((_) {});
  }

  void _onNotification(NotificationEvent e) {
    unreadNotifications.value = e.unreadCount;
    // The list preview/unread counts are refreshed by ConversationUpdated; here we
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

  Future<void> loadConversations({bool silent = false}) async {
    if (!silent) isLoading.value = true;
    hasError.value = false;
    try {
      final res = await service.getConversations(pageSize: 40);
      conversations.value = res.conversations;
    } catch (_) {
      if (!silent) hasError.value = true;
    } finally {
      isLoading.value = false;
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
      } catch (_) {
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
      conversations[i] = conversations[i].copyWith(
        unreadCount: 0,
        clearUnreadPriority: true,
        hasUnreadMention: false,
      );
      conversations.refresh();
    }
  }

  // ── Inbox actions ─────────────────────────────────────

  void setFilter(ConversationFilter f) => filter.value = f;
  void setSearchQuery(String q) => searchQuery.value = q;

  void clearFilters() {
    filter.value = ConversationFilter.all;
    searchQuery.value = '';
  }

  /// The list after the active chip and search box are applied.
  ///
  /// Server order is preserved (pinned first, then most recent) — no extra client sort,
  /// so the inbox never disagrees with the web client about ordering.
  List<ConversationSummary> get filteredConversations {
    final q = searchQuery.value.trim().toLowerCase();
    return conversations.where((c) {
      switch (filter.value) {
        case ConversationFilter.unread:
          if (c.unreadCount == 0) return false;
          break;
        case ConversationFilter.mentions:
          if (!c.hasUnreadMention) return false;
          break;
        case ConversationFilter.groups:
          if (c.isDirect) return false;
          break;
        case ConversationFilter.all:
          break;
      }
      if (q.isEmpty) return true;
      final title = (c.title ?? '').toLowerCase();
      final preview = (c.lastMessagePreview ?? '').toLowerCase();
      return title.contains(q) || preview.contains(q);
    }).toList();
  }

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
    conversations.refresh();
    try {
      await service.setConversationPinned(conversationId, next);
      // Pinning changes the server's ordering, so re-pull to land in the right slot.
      await loadConversations(silent: true);
    } catch (_) {
      final j = conversations.indexWhere((c) => c.id == conversationId);
      if (j >= 0) {
        conversations[j] = conversations[j].copyWith(isPinned: !next);
        conversations.refresh();
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
    _convUpdatedSub?.cancel();
    _resyncSub?.cancel();
    _notificationSub?.cancel();
    _notificationCountSub?.cancel();
    _toast.close();
    signalR.disconnect();
    super.onClose();
  }
}
