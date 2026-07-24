import 'package:flutter/material.dart';

/// Communication-module palette, mirrored from the Angular web module's
/// `communication-theme.css` (`--comm-*` tokens) so the two clients read as the
/// same product. Kept separate from [TColors] because the messenger deliberately
/// uses the web module's blue accent rather than the app's navy.
class CommColors {
  CommColors._();

  static const Color blue = Color(0xFF2563EB);
  static const Color blueDark = Color(0xFF1D4ED8);
  static const Color blueSoft = Color(0xFFEFF6FF);
  static const Color ink = Color(0xFF0F172A);
  static const Color ink2 = Color(0xFF1E293B);
  static const Color muted = Color(0xFF64748B);
  static const Color muted2 = Color(0xFF94A3B8);
  static const Color line = Color(0xFFE8EDF3);
  static const Color line2 = Color(0xFFF1F5F9);
  static const Color bg = Color(0xFFFFFFFF);
  static const Color bgSoft = Color(0xFFF8FAFC);
  static const Color red = Color(0xFFEF4444);
  static const Color green = Color(0xFF22C55E);
  static const Color amber = Color(0xFFF5B301);

  /// Deterministic avatar tint from an id — same intent as the web `tintFor`.
  static Color tintFor(int seed) {
    const palette = [
      Color(0xFF5B8DEF),
      Color(0xFF9C6ADE),
      Color(0xFF23A094),
      Color(0xFFE8833A),
      Color(0xFFD9534F),
      Color(0xFF3F9E5A),
    ];
    return palette[seed.abs() % palette.length];
  }
}
