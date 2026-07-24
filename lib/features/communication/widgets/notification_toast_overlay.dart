import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/messenger_controller.dart';
import '../screens/conversation_screen.dart';
import '../services/chat_signalr_service.dart';
import '../theme/comm_colors.dart';
import 'comm_avatar.dart';

/// App-global host for the messenger toast. Plugged into `GetMaterialApp.builder`
/// so it sits above EVERY route — the toast then appears no matter which module the
/// user is in (an incident detail, a campaign, the calendar…), not just the
/// messenger's own tabs. It's a no-op until the [MessengerController] exists (i.e.
/// after login), so the login/onboarding screens are unaffected.
class GlobalMessengerToastHost extends StatelessWidget {
  final Widget child;
  const GlobalMessengerToastHost({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        child,
        if (Get.isRegistered<MessengerController>())
          NotificationToastOverlay(
            stream: Get.find<MessengerController>().onToast,
            onOpen: (conversationId, title) {
              Get.to(() => ConversationScreen(
                    conversationId: conversationId,
                    title: title,
                  ));
            },
          ),
      ],
    );
  }
}

/// Global, top-anchored stack of auto-dismissing message toasts — the mobile
/// counterpart of the Angular `app-notification-toast`. It listens to a stream of
/// [AppNotification]s (the ones the controller decided warrant a toast, i.e. not the
/// conversation currently on screen) and renders a tappable card showing the sender,
/// their message, and a way into the thread.
class NotificationToastOverlay extends StatefulWidget {
  final Stream<AppNotification> stream;

  /// Opens the conversation the toast points at. Given (conversationId, title).
  final void Function(int conversationId, String title) onOpen;

  const NotificationToastOverlay({
    super.key,
    required this.stream,
    required this.onOpen,
  });

  @override
  State<NotificationToastOverlay> createState() => _NotificationToastOverlayState();
}

class _NotificationToastOverlayState extends State<NotificationToastOverlay> {
  static const _dismissAfter = Duration(seconds: 5);
  static const _maxVisible = 3;

  final List<_Toast> _toasts = [];
  StreamSubscription<AppNotification>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.stream.listen(_push);
  }

  void _push(AppNotification n) {
    final toast = _Toast(n);
    toast.timer = Timer(_dismissAfter, () => _dismiss(toast));
    setState(() {
      _toasts.insert(0, toast);
      while (_toasts.length > _maxVisible) {
        _toasts.removeLast().timer?.cancel();
      }
    });
  }

  void _dismiss(_Toast toast) {
    toast.timer?.cancel();
    if (!mounted) return;
    setState(() => _toasts.remove(toast));
  }

  @override
  void dispose() {
    _sub?.cancel();
    for (final t in _toasts) {
      t.timer?.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_toasts.isEmpty) return const SizedBox.shrink();
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 10,
      right: 10,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final t in _toasts)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _card(t),
            ),
        ],
      ),
    );
  }

  Widget _card(_Toast t) {
    final n = t.notification;
    final title = n.title ?? n.actorName ?? 'New message';
    final body = n.body ?? '';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          _dismiss(t);
          if (n.conversationId != null) {
            widget.onOpen(n.conversationId!, title);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: CommColors.bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CommColors.line),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommAvatar(
                name: n.actorName ?? title,
                seed: n.actorCaisseId ?? n.conversationId ?? 0,
                size: 40,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.send_rounded, size: 13, color: CommColors.blue),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: CommColors.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (body.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: CommColors.muted),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close, size: 18, color: CommColors.muted2),
                onPressed: () => _dismiss(t),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Toast {
  final AppNotification notification;
  Timer? timer;
  _Toast(this.notification);
}
