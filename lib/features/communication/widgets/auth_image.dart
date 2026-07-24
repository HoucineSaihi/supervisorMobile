import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../services/messenger_service.dart';
import '../theme/comm_colors.dart';

/// Renders an attachment image fetched through the authorized content route.
///
/// Since E-R2, attachment bytes are membership-checked server-side, so a plain
/// `Image.network` (which sends no auth header) would 401. This fetches via Dio —
/// where the auth interceptor applies — and shows a placeholder until the bytes
/// arrive. A tiny in-memory cache avoids re-downloading on every rebuild.
class AuthImage extends StatefulWidget {
  final String relativeUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const AuthImage({
    super.key,
    required this.relativeUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  static final Map<String, Uint8List> _cache = {};

  @override
  State<AuthImage> createState() => _AuthImageState();
}

class _AuthImageState extends State<AuthImage> {
  static final _service = MessengerService();
  Uint8List? _bytes;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cached = AuthImage._cache[widget.relativeUrl];
    if (cached != null) {
      setState(() => _bytes = cached);
      return;
    }
    try {
      final data = await _service.downloadAttachment(widget.relativeUrl);
      final bytes = Uint8List.fromList(data);
      AuthImage._cache[widget.relativeUrl] = bytes;
      if (mounted) setState(() => _bytes = bytes);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.memory(_bytes!, width: widget.width, height: widget.height, fit: widget.fit),
      );
    }
    return Container(
      width: widget.width ?? 200,
      height: widget.height ?? 150,
      decoration: BoxDecoration(color: CommColors.line2, borderRadius: BorderRadius.circular(10)),
      alignment: Alignment.center,
      child: Icon(
        _failed ? Icons.image_not_supported_outlined : Icons.image_outlined,
        color: CommColors.muted2,
      ),
    );
  }
}
