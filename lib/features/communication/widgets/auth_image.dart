import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/message.dart';
import '../services/media_cache.dart';
import '../theme/comm_colors.dart';

/// Renders a messenger image through [MediaCache] (authorized download, disk + memory
/// cache). Bubbles and galleries ask for [MediaVariant.thumb]; only the full-screen
/// viewer asks for the original.
///
/// While the bytes load it paints the server's tiny inline placeholder, blurred, at
/// the final size — the bubble never jumps, and there's something to see instantly.
class AuthImage extends StatefulWidget {
  final MessageAttachment attachment;
  final MediaVariant variant;
  final double? width;
  final double? height;
  final BoxFit fit;

  const AuthImage({
    super.key,
    required this.attachment,
    this.variant = MediaVariant.thumb,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  State<AuthImage> createState() => _AuthImageState();
}

class _AuthImageState extends State<AuthImage> {
  Uint8List? _bytes;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AuthImage old) {
    super.didUpdateWidget(old);
    // A recycled State (list reuse, optimistic → confirmed swap) must not keep
    // showing the previous attachment.
    if (old.attachment.id != widget.attachment.id || old.variant != widget.variant) {
      _bytes = null;
      _failed = false;
      _load();
    }
  }

  Future<void> _load() async {
    final cache = MediaCache.instance;
    final instant = cache.peek(widget.attachment, variant: widget.variant);
    if (instant != null) {
      setState(() => _bytes = instant);
      return;
    }
    try {
      final data = await cache.bytes(widget.attachment, variant: widget.variant);
      if (mounted) setState(() => _bytes = data);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _retry() {
    setState(() => _failed = false);
    _load();
  }

  /// Decode at display size, not source size: a 480px thumbnail in a 220px bubble (or
  /// an original in the viewer) shouldn't hold a full-resolution bitmap in memory.
  int? _cacheWidth(BuildContext context) {
    final w = widget.width;
    if (w == null || !w.isFinite) return null;
    return (w * MediaQuery.of(context).devicePixelRatio).round();
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    if (bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.memory(
          bytes,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          cacheWidth: _cacheWidth(context),
          gaplessPlayback: true,
        ),
      );
    }

    final placeholder = _placeholderBytes();
    return GestureDetector(
      onTap: _failed ? _retry : null,
      child: Container(
        width: widget.width ?? 200,
        height: widget.height ?? 150,
        decoration: BoxDecoration(color: CommColors.line2, borderRadius: BorderRadius.circular(10)),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (placeholder != null)
              ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Image.memory(placeholder, fit: BoxFit.cover, gaplessPlayback: true),
              ),
            if (placeholder == null || _failed)
              Center(
                child: Icon(
                  _failed ? Icons.refresh : Icons.image_outlined,
                  color: CommColors.muted2,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Uint8List? _placeholderBytes() {
    final uri = widget.attachment.placeholderDataUri;
    if (uri == null) return null;
    final comma = uri.indexOf(',');
    if (comma < 0) return null;
    try {
      return base64Decode(uri.substring(comma + 1));
    } catch (_) {
      return null;
    }
  }
}
