import 'package:flutter/material.dart';

/// Header comments chip with pulsing badge when [unreadCount] > 0.
class ExecutionCommentsButton extends StatefulWidget {
  final int unreadCount;
  final String label;
  final VoidCallback onTap;

  const ExecutionCommentsButton({
    super.key,
    required this.unreadCount,
    required this.label,
    required this.onTap,
  });

  @override
  State<ExecutionCommentsButton> createState() =>
      _ExecutionCommentsButtonState();
}

class _ExecutionCommentsButtonState extends State<ExecutionCommentsButton>
    with SingleTickerProviderStateMixin {
  static const Color _unreadRed = Color(0xFFE74C3C);
  static const Color _unreadGlow = Color(0xFFFF8A80);

  late final AnimationController _controller;
  late final Animation<double> _badgeScale;
  late final Animation<double> _ringOpacity;
  late final Animation<double> _chipGlow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _badgeScale = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _ringOpacity = Tween<double>(begin: 0.55, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _chipGlow = Tween<double>(begin: 0.12, end: 0.32).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _syncAnimation();
  }

  @override
  void didUpdateWidget(ExecutionCommentsButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.unreadCount != widget.unreadCount) {
      _syncAnimation();
    }
  }

  void _syncAnimation() {
    if (widget.unreadCount > 0) {
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
    } else {
      _controller
        ..stop()
        ..reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = widget.unreadCount > 0;
    final badgeLabel =
        widget.unreadCount > 99 ? '99+' : '${widget.unreadCount}';

    return Semantics(
      button: true,
      label: hasUnread
          ? '${widget.label}, $badgeLabel non lus'
          : widget.label,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                if (hasUnread)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: _unreadRed.withOpacity(_chipGlow.value),
                            blurRadius: 14,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(
                      hasUnread ? 0.22 : 0.15,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: hasUnread
                          ? Colors.white.withOpacity(0.55)
                          : Colors.white.withOpacity(0.25),
                      width: hasUnread ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasUnread
                            ? Icons.mark_chat_unread_rounded
                            : Icons.chat_bubble_outline_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              hasUnread ? FontWeight.w700 : FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasUnread) ...[
                  Positioned(
                    top: -6,
                    right: -6,
                    child: ScaleTransition(
                      scale: _badgeScale,
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _unreadGlow.withOpacity(_ringOpacity.value),
                                width: 2.5,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            constraints: const BoxConstraints(minWidth: 18),
                            decoration: BoxDecoration(
                              color: _unreadRed,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _unreadRed.withOpacity(0.45),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              badgeLabel,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
