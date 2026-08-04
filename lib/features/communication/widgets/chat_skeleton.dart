import 'package:flutter/material.dart';

import '../theme/comm_colors.dart';

/// Placeholder bubbles shown while a thread's history loads.
///
/// Alternating sides so the shape reads as a conversation immediately, instead of the
/// blank pause a spinner gives you.
class ChatSkeleton extends StatefulWidget {
  const ChatSkeleton({super.key});

  @override
  State<ChatSkeleton> createState() => _ChatSkeletonState();
}

class _ChatSkeletonState extends State<ChatSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  // Rough bubble widths, so the fake thread looks conversational rather than uniform.
  static const _rows = <(bool isOwn, double width, double height)>[
    (false, 0.55, 42),
    (false, 0.40, 34),
    (true, 0.62, 52),
    (false, 0.48, 34),
    (true, 0.35, 34),
    (false, 0.58, 42),
  ];

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxW = MediaQuery.of(context).size.width;
    return IgnorePointer(
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.45, end: 0.85).animate(_pulse),
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          children: _rows.map((r) {
            final (isOwn, w, h) = r;
            return Align(
              alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: maxW * w,
                height: h,
                margin: const EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                  color: isOwn ? const Color(0xFFDBEAFE) : CommColors.line,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(14),
                    topRight: const Radius.circular(14),
                    bottomLeft: Radius.circular(isOwn ? 14 : 4),
                    bottomRight: Radius.circular(isOwn ? 4 : 14),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
