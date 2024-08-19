import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_editor_plus/image_editor_plus.dart';
import 'package:image_editor_plus/options.dart';

class CaptureImageScreen extends StatefulWidget {
  @override
  _CaptureImageScreenState createState() => _CaptureImageScreenState();
}

class _CaptureImageScreenState extends State<CaptureImageScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  double _currentZoom = 1.0; // Default zoom level
  double _minZoom = 1.0; // Minimum zoom level
  double _maxZoom = 1.0; // Maximum zoom level

  // Variable to store the captured image
  XFile? image;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      CameraDescription(
        name: 'camera',
        lensDirection: CameraLensDirection.back,
        sensorOrientation: 0,
      ),
      ResolutionPreset.high,
    );
    _initializeControllerFuture = _controller.initialize().then((_) async {
      // Fetch the min and max zoom levels once the controller is initialized
      final minZoom = await _controller.getMinZoomLevel();
      final maxZoom = await _controller.getMaxZoomLevel();
      setState(() {
        _minZoom = minZoom;
        _maxZoom = maxZoom;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    await _initializeControllerFuture;
    final XFile? imageFile = await _controller.takePicture();

    if (imageFile != null) {
      final imagePath = imageFile.path;
      final imageBytes = await File(imagePath).readAsBytes();
      final imageUint8List = Uint8List.fromList(imageBytes);

      final Uint8List? editedImage = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ImageEditor(
            image: imageUint8List,
            cropOption: CropOption(),
            blurOption: BlurOption(),
            brushOption: BrushOption(),
            emojiOption: EmojiOption(),
            filtersOption: FiltersOption(),
            flipOption: FlipOption(),
            rotateOption: RotateOption(),
            textOption: TextOption(),
          ),
        ),
      );

      if (editedImage != null) {
        Navigator.pop(context, editedImage);
      } else {
        print('Failed to save edited image');
      }
    }
  }

  Future<bool> updateQuestionResponse(Uint8List editedImage) async {
    try {
      final tempFile = File('${Directory.systemTemp.path}/temp_image.png');
      await tempFile.writeAsBytes(editedImage);
      image = XFile(tempFile.path);
      return true;
    } catch (e) {
      print('Error updating question response: $e');
      return false;
    }
  }

  void _zoomIn() async {
    setState(() {
      _currentZoom = (_currentZoom + 0.1).clamp(_minZoom, _maxZoom);
      _controller.setZoomLevel(_currentZoom);
    });
  }

  void _zoomOut() async {
    setState(() {
      _currentZoom = (_currentZoom - 0.1).clamp(_minZoom, _maxZoom);
      _controller.setZoomLevel(_currentZoom);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Capture Image'),
        ),
        body: FutureBuilder<void>(
          future: _initializeControllerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return Column(
                children: [
                  Expanded(
                    child: CameraPreview(_controller),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _zoomOut,
                              icon: Icon(Icons.zoom_out, size: 20),
                              label: Text('Zoom Out', style: TextStyle(fontSize: 14)),
                              style: OutlinedButton.styleFrom(
                                minimumSize: Size(80, 40),
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: _captureImage,
                              icon: Icon(Icons.camera_alt, size: 20),
                              label: Text('Capture', style: TextStyle(fontSize: 14)),
                              style: OutlinedButton.styleFrom(
                                minimumSize: Size(80, 40),
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: _zoomIn,
                              icon: Icon(Icons.zoom_in, size: 20),
                              label: Text('Zoom In', style: TextStyle(fontSize: 14)),
                              style: OutlinedButton.styleFrom(
                                minimumSize: Size(80, 40),
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context, image?.path);
                              },
                              child: Text('Cancel', style: TextStyle(fontSize: 14)),
                              style: OutlinedButton.styleFrom(
                                minimumSize: Size(80, 40),
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            } else {
              return Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }


}
