import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/message.dart';
import '../services/messenger_service.dart';
import '../theme/comm_colors.dart';

/// Playback bubble for a voice attachment.
///
/// Attachment bytes are membership-checked server-side (E-R2), so the URL can't be
/// handed straight to the player — it sends no auth header and would 401. Instead the
/// clip is fetched through Dio (auth interceptor applies), cached to a temp file, and
/// played from there, since just_audio needs a file/URL rather than a byte array.
class VoicePlayer extends StatefulWidget {
  final MessageAttachment attachment;

  /// Own messages sit on a blue bubble, so the controls need lighter contrast.
  final bool isOwn;

  const VoicePlayer({super.key, required this.attachment, this.isOwn = false});

  @override
  State<VoicePlayer> createState() => _VoicePlayerState();
}

class _VoicePlayerState extends State<VoicePlayer> {
  static final _service = MessengerService();

  final _player = AudioPlayer();
  bool _preparing = false;
  bool _failed = false;
  bool _ready = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  /// Downloads on first play rather than on build — a thread can hold many voice
  /// notes, and fetching them all eagerly would burn a field user's data.
  Future<void> _prepare() async {
    if (_ready || _preparing) return;
    setState(() {
      _preparing = true;
      _failed = false;
    });
    try {
      final dir = await getTemporaryDirectory();
      // Key the cache on the attachment id: urls are stable but ids are shorter and
      // already unique per stored blob.
      final ext = _extensionFor(widget.attachment);
      final file = File(p.join(dir.path, 'voice_${widget.attachment.id}$ext'));

      if (!await file.exists()) {
        final bytes = await _service.downloadAttachment(widget.attachment.url);
        if (bytes.isEmpty) throw Exception('empty');
        await file.writeAsBytes(bytes, flush: true);
      }

      await _player.setFilePath(file.path);
      if (mounted) {
        setState(() {
          _ready = true;
          _preparing = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _failed = true;
          _preparing = false;
        });
      }
    }
  }

  /// just_audio picks its decoder partly from the file extension, so a clip recorded
  /// in the browser (webm/Opus) must not be handed over as ".m4a" or the platform
  /// decoder mis-parses it. Derive the extension from the server's content type and
  /// fall back to the stored file name.
  String _extensionFor(MessageAttachment a) {
    switch (a.contentType.toLowerCase()) {
      case 'audio/mp4':
      case 'audio/aac':
        return '.m4a';
      case 'audio/mpeg':
        return '.mp3';
      case 'audio/wav':
      case 'audio/x-wav':
        return '.wav';
      case 'audio/ogg':
        return '.ogg';
      case 'audio/webm':
        return '.webm';
      default:
        final e = p.extension(a.fileName);
        return e.isNotEmpty ? e : '.m4a';
    }
  }

  Future<void> _toggle() async {
    if (!_ready) {
      await _prepare();
      if (!_ready) return;
    }
    if (_player.playing) {
      await _player.pause();
    } else {
      // Restart when the previous run finished, otherwise play() would no-op at the end.
      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
      }
      await _player.play();
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString();
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.isOwn ? CommColors.blueDark : CommColors.blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 240),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CommColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _failed ? _prepare : _toggle,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: _preparing
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : StreamBuilder<PlayerState>(
                      stream: _player.playerStateStream,
                      builder: (_, snap) {
                        final playing = snap.data?.playing ?? false;
                        final done = snap.data?.processingState == ProcessingState.completed;
                        return Icon(
                          _failed
                              ? Icons.refresh
                              : (playing && !done ? Icons.pause : Icons.play_arrow),
                          color: Colors.white,
                          size: 20,
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                StreamBuilder<Duration>(
                  stream: _player.positionStream,
                  builder: (_, posSnap) {
                    final pos = posSnap.data ?? Duration.zero;
                    // Prefer the server-recorded duration: it is known before the clip
                    // is downloaded, so the bar is meaningful on first paint.
                    final total = _player.duration ??
                        (widget.attachment.durationSeconds != null
                            ? Duration(seconds: widget.attachment.durationSeconds!)
                            : Duration.zero);
                    final frac = total.inMilliseconds == 0
                        ? 0.0
                        : (pos.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: frac,
                            minHeight: 4,
                            backgroundColor: CommColors.line2,
                            valueColor: AlwaysStoppedAnimation(accent),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _failed
                              ? 'Tap to retry'
                              : '${_fmt(pos)} / ${total == Duration.zero ? '--:--' : _fmt(total)}',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: _failed ? CommColors.red : CommColors.muted2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.mic, size: 15, color: accent),
        ],
      ),
    );
  }
}
