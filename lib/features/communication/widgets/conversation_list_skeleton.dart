import 'package:flutter/material.dart';

import '../theme/comm_colors.dart';

/// Placeholder rows shown while the inbox loads for the first time.
///
/// Deliberately shaped like the real row rather than a spinner: the list keeps its
/// layout, so content appears in place instead of the screen jumping when it arrives.
class ConversationListSkeleton extends StatefulWidget {
  final int rows;

  const ConversationListSkeleton({super.key, this.rows = 7});

  @override
  State<ConversationListSkeleton> createState() => _ConversationListSkeletonState();
}

class _ConversationListSkeletonState extends State<ConversationListSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    // A gentle pulse rather than a shimmer sweep — same "this is loading" signal
    // without pulling in an animation package for it.
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
    return IgnorePointer(
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.45, end: 0.85).animate(_pulse),
        child: ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: widget.rows,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, indent: 76, color: CommColors.line2),
          itemBuilder: (_, i) => const _SkeletonRow(),
        ),
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: CommColors.line,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const _Bar(width: 130, height: 12),
                    const Spacer(),
                    _Bar(width: 32, height: 10, color: CommColors.line2),
                  ],
                ),
                const SizedBox(height: 9),
                const _Bar(width: double.infinity, height: 10),
                const SizedBox(height: 6),
                const _Bar(width: 180, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double width;
  final double height;
  final Color color;

  const _Bar({
    required this.width,
    required this.height,
    this.color = CommColors.line,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
