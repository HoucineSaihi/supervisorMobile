import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import '../models/conversation.dart';
import '../services/chat_signalr_service.dart';
import '../services/messenger_service.dart';
import '../services/offline_queue.dart';

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

  Future<void> _bootstrap() async {
    final id = await _storage.read(key: 'currentUserId');
    currentUserId = int.tryParse(id ?? '') ?? 0;

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
  void markConversationRead(int conversationId) {
    final i = conversations.indexWhere((c) => c.id == conversationId);
    if (i >= 0 && conversations[i].unreadCount > 0) {
      conversations[i] = conversations[i].copyWith(unreadCount: 0);
      conversations.refresh();
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
