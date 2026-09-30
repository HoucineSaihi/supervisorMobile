import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../theme/comm_colors.dart';

/// Tap-to-start / tap-to-stop mic button for recording a voice message.
///
/// A single tap begins recording; the icon swaps to a stop square and an elapsed-
/// time readout appears right in the composer bar so it's unmistakable that
/// recording is live. A second tap stops it and hands the file to [onStopped] —
/// the caller stages it for review/playback/caption rather than sending it
/// immediately, so nothing about this widget itself decides to send.
class VoiceRecorderButton extends StatefulWidget {
  final void Function(String filePath, int durationSeconds) onStopped;

  /// Below this, stopping is treated as "nothing worth keeping" and the clip is
  /// discarded rather than staged — too short to be an intentional message, more
  /// likely a mis-tap immediately undone.
  static const minDuration = Duration(milliseconds: 800);

  const VoiceRecorderButton({super.key, required this.onStopped});

  @override
  State<VoiceRecorderButton> createState() => _VoiceRecorderButtonState();
}

class _VoiceRecorderButtonState extends State<VoiceRecorderButton> {
  final _recorder = AudioRecorder();

  bool _recording = false;
  DateTime? _startedAt;
  Timer? _ticker;
  Duration _elapsed = Duration.zero;

  @override
  void dispose() {
    _ticker?.cancel();
    // Fire-and-forget: if a recording is still in flight when the widget is torn
    // down (e.g. navigating away mid-recording), stop it so the recorder doesn't
    // leak, but there's nothing left to hand the clip to.
    if (_recording) _recorder.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _toggle() => _recording ? _stop() : _start();

  Future<void> _start() async {
    if (_recording) return;
    try {
      if (!await _recorder.hasPermission()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission is needed to record a voice message')),
          );
        }
        return;
      }

      final dir = await getTemporaryDirectory();
      final path = p.join(dir.path, 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a');

      await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);

      _startedAt = DateTime.now();
      setState(() {
        _recording = true;
        _elapsed = Duration.zero;
      });

      _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
        if (!mounted || _startedAt == null) return;
        setState(() => _elapsed = DateTime.now().difference(_startedAt!));
      });
    } catch (_) {
      _recording = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not start recording')),
        );
      }
    }
  }

  Future<void> _stop() async {
    if (!_recording) return;
    _ticker?.cancel();
    _ticker = null;
    final duration = _elapsed;
    _startedAt = null;
    setState(() => _recording = false);

    try {
      final path = await _recorder.stop();
      if (path == null) return;

      if (duration < VoiceRecorderButton.minDuration) {
        final f = File(path);
        if (await f.exists()) await f.delete();
        return;
      }

      widget.onStopped(path, duration.inSeconds.clamp(1, 1 << 30));
    } catch (_) {
      // Nothing usable came out of this recording — silently drop it rather than
      // surface an error for what the user experiences as a completed action.
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTap: _toggle,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: _recording ? CommColors.red : CommColors.blue,
          shape: BoxShape.circle,
        ),
        child: Icon(
          _recording ? Icons.stop_rounded : Icons.mic,
          color: Colors.white,
          size: 20,
        ),
      ),
    );

    if (!_recording) return button;

    // A clear, impossible-to-miss "recording" state: a pulsing dot + live timer
    // sitting inline in the composer bar (not a floating overlay) so it reads as
    // part of the row rather than something that might disappear if you look away.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: CommColors.red.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _RecordingDot(),
              const SizedBox(width: 6),
              Text(
                _fmt(_elapsed),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: CommColors.red,
                ),
              ),
            ],
          ),
        ),
        button,
      ],
    );
  }
}

/// A small dot that fades in and out on a loop, the standard "recording is live"
/// cue (matches the red dot in a phone's own status bar while mic access is active).
class _RecordingDot extends StatefulWidget {
  const _RecordingDot();

  @override
  State<_RecordingDot> createState() => _RecordingDotState();
}

class _RecordingDotState extends State<_RecordingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.3, end: 1.0).animate(_controller),
      child: const Icon(Icons.circle, size: 10, color: CommColors.red),
    );
  }
}
