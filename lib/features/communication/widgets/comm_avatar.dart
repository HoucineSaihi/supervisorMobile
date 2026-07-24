import 'package:flutter/material.dart';

import '../theme/comm_colors.dart';

/// Circular initials avatar with an optional presence dot — the mobile counterpart
/// of the web `.comm-avatar`.
class CommAvatar extends StatelessWidget {
  final String? name;
  final int seed;
  final double size;
  final bool online;
  final bool showPresence;

  const CommAvatar({
    super.key,
    required this.name,
    required this.seed,
    this.size = 44,
    this.online = false,
    this.showPresence = false,
  });

  String get _initials {
    final n = (name ?? '').trim();
    if (n.isEmpty) return '?';
    final parts = n.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.characters.take(2).toString().toUpperCase();
    }
    return (parts.first.characters.first + parts[1].characters.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final dot = size * 0.22;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [CommColors.tintFor(seed), CommColors.tintFor(seed + 3)],
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              _initials,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: size * 0.36,
              ),
            ),
          ),
          if (showPresence && online)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: dot,
                height: dot,
                decoration: BoxDecoration(
                  color: CommColors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
