import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../theme/comm_colors.dart';

/// What the annotator hands back: the file to send, and whether it carries markup.
class AnnotatedImage {
  final String path;
  final String fileName;
  final bool isAnnotated;
  final int? width;
  final int? height;

  const AnnotatedImage({
    required this.path,
    required this.fileName,
    required this.isAnnotated,
    this.width,
    this.height,
  });
}

/// Opens the photo markup screen for a just-taken or just-picked image.
///
/// Resolves to the image to send — flattened with the drawings when there are any,
/// the original untouched otherwise — or null when the user backs out (nothing is
/// sent). Mirrors the web's image annotator: pen, arrow, rectangle, six colours,
/// undo and clear.
Future<AnnotatedImage?> openImageAnnotator(BuildContext context, String imagePath) {
  return Navigator.of(context).push<AnnotatedImage>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => ImageAnnotatorScreen(imagePath: imagePath),
    ),
  );
}

enum _Tool { pen, arrow, rect }

/// One drawn shape. Points are normalized (0..1 of the image's width/height) so the
/// same strokes render on the on-screen preview and on the full-size export.
class _Stroke {
  final _Tool tool;
  final Color colour;
  final List<Offset> points;

  _Stroke(this.tool, this.colour, this.points);
}

class ImageAnnotatorScreen extends StatefulWidget {
  final String imagePath;

  const ImageAnnotatorScreen({super.key, required this.imagePath});

  @override
  State<ImageAnnotatorScreen> createState() => _ImageAnnotatorScreenState();
}

class _ImageAnnotatorScreenState extends State<ImageAnnotatorScreen> {
  static const _colours = [
    Color(0xFFEF4444),
    Color(0xFFF59E0B),
    Color(0xFF22C55E),
    Color(0xFF2563EB),
    Color(0xFF0F172A),
    Color(0xFFFFFFFF),
  ];

  ui.Image? _image;
  String? _loadError;

  _Tool _tool = _Tool.pen;
  Color _colour = _colours.first;
  final _strokes = <_Stroke>[];
  _Stroke? _current;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final bytes = await File(widget.imagePath).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      if (!mounted) {
        frame.image.dispose();
        return;
      }
      setState(() => _image = frame.image);
    } catch (_) {
      if (mounted) setState(() => _loadError = 'Could not open this image');
    }
  }

  // ── Drawing ───────────────────────────────────────────

  Offset _normalize(Offset local, Size size) => Offset(
        (local.dx / size.width).clamp(0.0, 1.0),
        (local.dy / size.height).clamp(0.0, 1.0),
      );

  void _onPanStart(DragStartDetails d, Size size) {
    setState(() => _current = _Stroke(_tool, _colour, [_normalize(d.localPosition, size)]));
  }

  void _onPanUpdate(DragUpdateDetails d, Size size) {
    final current = _current;
    if (current == null) return;
    final point = _normalize(d.localPosition, size);
    setState(() {
      if (current.tool == _Tool.pen) {
        current.points.add(point);
      } else if (current.points.length == 1) {
        // Arrow and rectangle only need start and current end.
        current.points.add(point);
      } else {
        current.points[1] = point;
      }
    });
  }

  void _onPanEnd() {
    setState(() {
      final current = _current;
      if (current != null && current.points.length > 1) _strokes.add(current);
      _current = null;
    });
  }

  void _undo() => setState(() {
        if (_strokes.isNotEmpty) _strokes.removeLast();
      });

  void _clear() => setState(_strokes.clear);

  // ── Export ────────────────────────────────────────────

  /// Flattens the drawings onto the full-size image and re-encodes as JPEG. With no
  /// drawings the original goes out unchanged (and isn't flagged as annotated).
  Future<void> _send() async {
    final image = _image;
    if (image == null || _exporting) return;

    if (_strokes.isEmpty) {
      Navigator.of(context).pop(AnnotatedImage(
        path: widget.imagePath,
        fileName: p.basename(widget.imagePath),
        isAnnotated: false,
        width: image.width,
        height: image.height,
      ));
      return;
    }

    setState(() => _exporting = true);
    try {
      final size = Size(image.width.toDouble(), image.height.toDouble());
      final recorder = ui.PictureRecorder();
      _AnnotationPainter(image: image, strokes: _strokes).paint(Canvas(recorder), size);
      final flattened = await recorder.endRecording().toImage(image.width, image.height);
      final png = await flattened.toByteData(format: ui.ImageByteFormat.png);
      flattened.dispose();
      if (png == null) throw StateError('encode failed');

      // dart:ui only encodes PNG — several MB for a photo. Re-encode to JPEG on the
      // device (no service involved), same quality the web annotator exports at.
      final jpeg = await FlutterImageCompress.compressWithList(
        png.buffer.asUint8List(),
        quality: 88,
        format: CompressFormat.jpeg,
      );

      final dir = await getTemporaryDirectory();
      final name = '${p.basenameWithoutExtension(widget.imagePath)}-annotated.jpg';
      final out = File(p.join(dir.path, '${DateTime.now().millisecondsSinceEpoch}-$name'));
      await out.writeAsBytes(jpeg, flush: true);

      if (!mounted) return;
      Navigator.of(context).pop(AnnotatedImage(
        path: out.path,
        fileName: name,
        isAnnotated: true,
        width: image.width,
        height: image.height,
      ));
    } catch (_) {
      if (!mounted) return;
      setState(() => _exporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save the marked-up photo')),
      );
    }
  }

  // ── UI ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            Expanded(child: _canvasArea()),
            _toolbar(),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Cancel',
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: _exporting ? null : () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Mark up photo',
                    style: TextStyle(
                        color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                Text('Circle or point at what matters — optional',
                    style: TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Undo',
            icon: Icon(Icons.undo, color: _strokes.isEmpty ? Colors.white30 : Colors.white),
            onPressed: _strokes.isEmpty || _exporting ? null : _undo,
          ),
          IconButton(
            tooltip: 'Clear',
            icon: Icon(Icons.delete_outline,
                color: _strokes.isEmpty ? Colors.white30 : Colors.white),
            onPressed: _strokes.isEmpty || _exporting ? null : _clear,
          ),
        ],
      ),
    );
  }

  Widget _canvasArea() {
    final image = _image;
    if (_loadError != null) {
      return Center(
        child: Text(_loadError!, style: const TextStyle(color: Colors.white70)),
      );
    }
    if (image == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return LayoutBuilder(builder: (context, constraints) {
      // Fit the photo inside the available area, keeping its aspect ratio.
      final scale = math.min(
        constraints.maxWidth / image.width,
        constraints.maxHeight / image.height,
      );
      final size = Size(image.width * scale, image.height * scale);

      return Center(
        child: SizedBox.fromSize(
          size: size,
          child: GestureDetector(
            onPanStart: (d) => _onPanStart(d, size),
            onPanUpdate: (d) => _onPanUpdate(d, size),
            onPanEnd: (_) => _onPanEnd(),
            onPanCancel: _onPanEnd,
            child: CustomPaint(
              size: size,
              painter: _AnnotationPainter(
                image: image,
                strokes: _strokes,
                current: _current,
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _toolbar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      color: const Color(0xFF111111),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _toolButton(_Tool.pen, Icons.edit_outlined, 'Pen'),
              _toolButton(_Tool.arrow, Icons.north_east, 'Arrow'),
              _toolButton(_Tool.rect, Icons.crop_square, 'Box'),
              const Spacer(),
              for (final c in _colours) _colourDot(c),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: CommColors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _image == null || _exporting ? null : _send,
              icon: _exporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(
                _strokes.isEmpty ? 'Send photo' : 'Send marked-up photo',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolButton(_Tool tool, IconData icon, String label) {
    final active = _tool == tool;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Tooltip(
        message: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => setState(() => _tool = tool),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: active ? Colors.white : Colors.white10,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: active ? Colors.black : Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _colourDot(Color c) {
    final active = _colour == c;
    return GestureDetector(
      onTap: () => setState(() => _colour = c),
      child: Container(
        width: 26,
        height: 26,
        margin: const EdgeInsets.only(left: 6),
        decoration: BoxDecoration(
          color: c,
          shape: BoxShape.circle,
          border: Border.all(
            color: active ? Colors.white : Colors.white24,
            width: active ? 3 : 1,
          ),
        ),
      ),
    );
  }
}

/// Paints the photo and the strokes at any size — the on-screen preview and the
/// full-resolution export share it, so what you see is what gets sent.
class _AnnotationPainter extends CustomPainter {
  final ui.Image image;
  final List<_Stroke> strokes;
  final _Stroke? current;

  _AnnotationPainter({
    required this.image,
    required this.strokes,
    this.current,
  });

  @override
  void paint(Canvas canvas, Size size) {
    paintImage(
      canvas: canvas,
      rect: Offset.zero & size,
      image: image,
      fit: BoxFit.fill,
      filterQuality: FilterQuality.medium,
    );

    // Purely proportional to the image, so the full-size export looks exactly like
    // the preview (~3px on a phone screen, ~13px on a 1920px photo).
    final width = size.longestSide * 0.007;
    for (final s in [...strokes, if (current != null) current!]) {
      _drawStroke(canvas, size, s, width);
    }
  }

  void _drawStroke(Canvas canvas, Size size, _Stroke stroke, double width) {
    if (stroke.points.isEmpty) return;
    final paint = Paint()
      ..color = stroke.colour
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    Offset at(Offset n) => Offset(n.dx * size.width, n.dy * size.height);
    final start = at(stroke.points.first);
    final end = at(stroke.points.last);

    switch (stroke.tool) {
      case _Tool.pen:
        final path = Path()..moveTo(start.dx, start.dy);
        for (final pt in stroke.points.skip(1)) {
          final o = at(pt);
          path.lineTo(o.dx, o.dy);
        }
        canvas.drawPath(path, paint);
        break;

      case _Tool.rect:
        canvas.drawRect(Rect.fromPoints(start, end), paint);
        break;

      case _Tool.arrow:
        canvas.drawLine(start, end, paint);
        final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
        final head = width * 4;
        for (final side in [-math.pi / 6, math.pi / 6]) {
          canvas.drawLine(
            end,
            Offset(end.dx - head * math.cos(angle + side), end.dy - head * math.sin(angle + side)),
            paint,
          );
        }
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _AnnotationPainter old) => true;
}
