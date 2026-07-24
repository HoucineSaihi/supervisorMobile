import 'package:flutter/material.dart';

import '../services/chat_signalr_service.dart';

/// Thin status strip shown while the socket isn't healthy. Without it a dropped
/// connection is indistinguishable from a quiet conversation — the "I never got your
/// message" failure mode. Mirrors the web connection banner.
class ConnectionBanner extends StatelessWidget {
  final ConnectionStatus status;
  final VoidCallback? onRetry;

  const ConnectionBanner({super.key, required this.status, this.onRetry});

  @override
  Widget build(BuildContext context) {
    if (status == ConnectionStatus.connected) return const SizedBox.shrink();

    final offline = status == ConnectionStatus.offline;
    final bg = offline ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB);
    final fg = offline ? const Color(0xFF991B1B) : const Color(0xFF92400E);

    String label;
    switch (status) {
      case ConnectionStatus.connecting:
        label = 'Connecting…';
        break;
      case ConnectionStatus.reconnecting:
        label = 'Reconnecting — messages may be delayed';
        break;
      case ConnectionStatus.offline:
        label = 'Disconnected — you are not receiving new messages';
        break;
      case ConnectionStatus.connected:
        label = '';
        break;
    }

    return Container(
      width: double.infinity,
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          if (offline && onRetry != null)
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  border: Border.all(color: fg),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('Retry', style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ),
        ],
      ),
    );
  }
}
