import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:signalr_netcore/iretry_policy.dart';

import '../models/message.dart';
import 'messenger_service.dart';

enum ConnectionStatus { connecting, connected, reconnecting, offline }

class ThreadEvent {
  final String type; // MessageReacted | MessageEdited | MessageDeleted | MessagePinned
  final int conversationId;
  final int messageId;
  ThreadEvent(this.type, this.conversationId, this.messageId);
}

class PresenceEvent {
  final int caisseId;
  final bool isOnline;
  PresenceEvent(this.caisseId, this.isOnline);
}

class ConversationReadEvent {
  final int conversationId;
  final int caisseId;
  final int lastReadSequence;
  ConversationReadEvent(this.conversationId, this.caisseId, this.lastReadSequence);
}

/// A per-recipient notification pushed on the user's personal group, exactly like
/// the Angular AppNotification. Carries what a toast needs (actor name, body,
/// conversation to open) plus the fresh unread badge total.
class AppNotification {
  final int id;
  final String? title;
  final String? body;
  final int? actorCaisseId;
  final String? actorName;
  final int? conversationId;
  final int? messageId;

  AppNotification({
    required this.id,
    this.title,
    this.body,
    this.actorCaisseId,
    this.actorName,
    this.conversationId,
    this.messageId,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: (j['id'] as num?)?.toInt() ?? 0,
        title: j['title'] as String?,
        body: j['body'] as String?,
        actorCaisseId: (j['actorCaisseId'] as num?)?.toInt(),
        actorName: j['actorName'] as String?,
        conversationId: (j['conversationId'] as num?)?.toInt(),
        messageId: (j['messageId'] as num?)?.toInt(),
      );
}

/// A pushed notification plus the recipient's up-to-date unread total.
class NotificationEvent {
  final AppNotification notification;
  final int unreadCount;
  NotificationEvent(this.notification, this.unreadCount);
}

/// Retry forever with capped exponential backoff plus jitter — same policy as the
/// Angular client. The default finite policy would permanently give up after a
/// short outage, leaving a field user silently cut off until they restart the app.
class _ForeverRetryPolicy implements IRetryPolicy {
  final _rng = Random();
  @override
  int? nextRetryDelayInMilliseconds(RetryContext retryContext) {
    final step = min(retryContext.previousRetryCount, 5);
    final base = min(30000, 1000 * pow(2, step).toInt());
    return base + _rng.nextInt(1000);
  }
}

/// Push-only realtime channel. Mirrors ChatSignalRService in the web app: it never
/// sends a persisted write (MessengerService/REST owns those), only receives pushes
/// and relays typing. Handles reconnect, resync-after-gap, and the Phase B/C/receipt
/// thread events.
class ChatSignalRService {
  final _storage = const FlutterSecureStorage();
  HubConnection? _hub;
  Future<void>? _startFuture;
  bool _disposed = false;
  Timer? _retryTimer;
  final Set<int> _joined = {};

  // ── Event streams (broadcast so multiple screens can listen) ──
  final _messageReceived = StreamController<Message>.broadcast();
  final _threadEvent = StreamController<ThreadEvent>.broadcast();
  final _presence = StreamController<PresenceEvent>.broadcast();
  final _conversationRead = StreamController<ConversationReadEvent>.broadcast();
  final _notification = StreamController<NotificationEvent>.broadcast();
  final _notificationCount = StreamController<int>.broadcast();
  final _conversationUpdated = StreamController<int>.broadcast();
  final _typing = StreamController<int>.broadcast(); // caisseId typing
  final _statusChanged = StreamController<int>.broadcast(); // messageId
  final _status = StreamController<ConnectionStatus>.broadcast();
  final _resyncRequired = StreamController<void>.broadcast();

  Stream<Message> get onMessage => _messageReceived.stream;
  Stream<ThreadEvent> get onThreadEvent => _threadEvent.stream;
  Stream<PresenceEvent> get onPresence => _presence.stream;
  Stream<ConversationReadEvent> get onConversationRead => _conversationRead.stream;

  /// Per-recipient notification (new message / mention / etc.) with the fresh
  /// unread badge total. Delivered on the user's personal group regardless of which
  /// screen they're on — this is what drives the global toast and the nav badge.
  Stream<NotificationEvent> get onNotification => _notification.stream;

  /// Unread badge resync (e.g. after marking read on another device).
  Stream<int> get onNotificationCount => _notificationCount.stream;
  Stream<int> get onConversationUpdated => _conversationUpdated.stream;
  Stream<int> get onTyping => _typing.stream;
  Stream<int> get onStatusChanged => _statusChanged.stream;
  Stream<ConnectionStatus> get onStatus => _status.stream;
  Stream<void> get onResyncRequired => _resyncRequired.stream;

  ConnectionStatus _current = ConnectionStatus.offline;
  ConnectionStatus get status => _current;

  bool get isConnected => _hub?.state == HubConnectionState.Connected;

  void _setStatus(ConnectionStatus s) {
    _current = s;
    if (!_status.isClosed) _status.add(s);
  }

  Future<void> connect() async {
    _disposed = false;
    if (isConnected) return;
    if (_startFuture != null) return _startFuture;

    _hub ??= _build();
    _startFuture = _start();
    try {
      await _startFuture;
    } finally {
      _startFuture = null;
    }
  }

  HubConnection _build() {
    final hubUrl = '${MessengerService.apiRoot}../hubs/chat'
        .replaceAll('/api/../', '/'); // -> <origin>/hubs/chat

    final hub = HubConnectionBuilder()
        .withUrl(
          hubUrl,
          options: HttpConnectionOptions(
            // WebSocket can't set an Authorization header, so the JWT rides the
            // query string; the backend reads ?access_token= for /hubs/* paths.
            // Re-read on every (re)connect so a refreshed token is picked up.
            accessTokenFactory: () async {
              final t = await _storage.read(key: 'token') ?? '';
              return t.replaceAll(RegExp(r'^\[|\]$'), '').trim();
            },
          ),
        )
        .withAutomaticReconnect(reconnectPolicy: _ForeverRetryPolicy())
        .build();

    hub.serverTimeoutInMilliseconds = 60000;
    hub.keepAliveIntervalInMilliseconds = 15000;

    _registerHandlers(hub);

    hub.onreconnecting(({error}) => _setStatus(ConnectionStatus.reconnecting));
    hub.onreconnected(({connectionId}) async {
      _setStatus(ConnectionStatus.connected);
      await _rejoinAll();
      // SignalR replays nothing across a reconnect — pull whatever was missed.
      if (!_resyncRequired.isClosed) _resyncRequired.add(null);
    });
    hub.onclose(({error}) {
      _setStatus(ConnectionStatus.offline);
      if (!_disposed) _scheduleRetry();
    });

    return hub;
  }

  void _registerHandlers(HubConnection hub) {
    _on(hub, 'ReceiveMessage', (args) {
      final m = _firstMap(args);
      if (m != null) _messageReceived.add(Message.fromJson(m));
    });

    _on(hub, 'Typing', (args) {
      // (conversationId, caisseId)
      if (args != null && args.length >= 2) {
        _typing.add((args[1] as num).toInt());
      }
    });

    _on(hub, 'PresenceChanged', (args) {
      // (caisseId, isOnline, lastSeenAt)
      if (args != null && args.length >= 2) {
        _presence.add(PresenceEvent((args[0] as num).toInt(), args[1] == true));
      }
    });

    _on(hub, 'ConversationUpdated', (args) {
      if (args != null && args.isNotEmpty) {
        _conversationUpdated.add((args[0] as num).toInt());
      }
    });

    _on(hub, 'MessageStatusChanged', (args) {
      if (args != null && args.isNotEmpty) {
        _statusChanged.add((args[0] as num).toInt());
      }
    });

    // (NotificationDto, unreadCount) — pushed on the user's personal group by
    // NotificationService.PersistAndPushAsync. Arrives on every screen, so this is
    // the single source for the global toast + nav badge.
    _on(hub, 'Notification', (args) {
      if (args == null || args.isEmpty) return;
      final m = _firstMap([args[0]]);
      if (m == null) return;
      final unread = args.length >= 2 ? (args[1] as num?)?.toInt() ?? 0 : 0;
      _notification.add(NotificationEvent(AppNotification.fromJson(m), unread));
    });

    _on(hub, 'NotificationCountChanged', (args) {
      if (args != null && args.isNotEmpty) {
        _notificationCount.add((args[0] as num).toInt());
      }
    });

    for (final type in ['MessageReacted', 'MessageEdited', 'MessageDeleted', 'MessagePinned']) {
      _on(hub, type, (args) {
        final p = _firstJson(args);
        if (p != null && p['conversationId'] != null && p['messageId'] != null) {
          _threadEvent.add(ThreadEvent(
            type,
            (p['conversationId'] as num).toInt(),
            (p['messageId'] as num).toInt(),
          ));
        }
      });
    }

    _on(hub, 'ConversationRead', (args) {
      final p = _firstJson(args);
      if (p != null && p['conversationId'] != null) {
        _conversationRead.add(ConversationReadEvent(
          (p['conversationId'] as num).toInt(),
          (p['caisseId'] as num?)?.toInt() ?? 0,
          (p['lastReadSequence'] as num?)?.toInt() ?? 0,
        ));
      }
    });
  }

  /// Registers a hub handler whose body can never tear down the connection. The
  /// underlying transport (signalr_netcore's WebSocketTransport) treats ANY exception
  /// thrown synchronously from a receive callback as fatal and closes the socket —
  /// so a single malformed or unexpectedly-shaped push (e.g. an enum arriving as an
  /// int) would knock the client offline and trigger a reconnect on every message.
  /// Swallowing here means one bad payload is dropped, not the whole feed.
  void _on(HubConnection hub, String method, void Function(List<Object?>? args) handler) {
    hub.on(method, (args) {
      try {
        handler(args);
      } catch (_) {
        // Deliberately swallowed: a parse failure must not close the socket.
      }
    });
  }

  /// ReceiveMessage carries the object directly; the Phase B/C events carry a JSON
  /// STRING (the outbox payload). This normalises both.
  Map<String, dynamic>? _firstJson(List<Object?>? args) {
    if (args == null || args.isEmpty) return null;
    final a = args[0];
    try {
      if (a is String) return jsonDecode(a) as Map<String, dynamic>;
      if (a is Map) return Map<String, dynamic>.from(a);
    } catch (_) {}
    return null;
  }

  Map<String, dynamic>? _firstMap(List<Object?>? args) {
    if (args == null || args.isEmpty) return null;
    final a = args[0];
    if (a is Map) return Map<String, dynamic>.from(a);
    if (a is String) {
      try {
        return jsonDecode(a) as Map<String, dynamic>;
      } catch (_) {}
    }
    return null;
  }

  Future<void> _start() async {
    if (_hub == null) return;
    if (_current == ConnectionStatus.offline) _setStatus(ConnectionStatus.connecting);
    try {
      await _hub!.start();
      _setStatus(ConnectionStatus.connected);
      await _rejoinAll();
      if (!_resyncRequired.isClosed) _resyncRequired.add(null);
    } catch (e) {
      _setStatus(ConnectionStatus.offline);
      if (!_disposed) _scheduleRetry();
      rethrow;
    }
  }

  /// withAutomaticReconnect only covers connections that were once up; a failed
  /// initial start or a hard close needs its own loop.
  void _scheduleRetry({int delayMs = 5000}) {
    if (_retryTimer != null || _disposed) return;
    _retryTimer = Timer(Duration(milliseconds: delayMs), () {
      _retryTimer = null;
      if (_disposed || isConnected) return;
      connect().catchError((_) {});
    });
  }

  Future<void> _rejoinAll() async {
    if (!isConnected) return;
    for (final id in _joined) {
      try {
        await _hub!.invoke('JoinConversation', args: [id]);
      } catch (_) {}
    }
  }

  Future<void> joinConversation(int conversationId) async {
    _joined.add(conversationId);
    try {
      await connect();
      if (isConnected) {
        await _hub!.invoke('JoinConversation', args: [conversationId]);
      }
    } catch (_) {
      // Membership is restored on reconnect; the resync then pulls anything missed.
    }
  }

  Future<void> leaveConversation(int conversationId) async {
    _joined.remove(conversationId);
    if (isConnected) {
      try {
        await _hub!.invoke('LeaveConversation', args: [conversationId]);
      } catch (_) {}
    }
  }

  Future<void> startTyping(int conversationId) async {
    if (!isConnected) return;
    try {
      await _hub!.invoke('StartTyping', args: [conversationId]);
    } catch (_) {}
  }

  /// Call when the app returns to foreground — a suspended socket may be dead with
  /// no event having fired, so resync unconditionally.
  void wakeUp() {
    if (_disposed || _hub == null) return;
    if (isConnected) {
      if (!_resyncRequired.isClosed) _resyncRequired.add(null);
      return;
    }
    _retryTimer?.cancel();
    _retryTimer = null;
    connect().catchError((_) {});
  }

  Future<void> disconnect() async {
    _disposed = true;
    _retryTimer?.cancel();
    _retryTimer = null;
    _joined.clear();
    try {
      await _hub?.stop();
    } catch (_) {}
    _hub = null;
    _setStatus(ConnectionStatus.offline);
  }
}
