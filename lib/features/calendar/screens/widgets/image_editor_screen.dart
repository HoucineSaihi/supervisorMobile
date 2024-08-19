import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_editor_plus/image_editor_plus.dart';
import 'package:image_editor_plus/options.dart';

class ImageEditorScreen extends StatelessWidget {
  final Uint8List image;
  final CropOption cropOption;
  final BlurOption blurOption;
  final BrushOption brushOption;
  final EmojiOption emojiOption;
  final FiltersOption filtersOption;
  final FlipOption flipOption;
  final RotateOption rotateOption;
  final TextOption textOption;

  ImageEditorScreen({
    required this.image,
    required this.cropOption,
    required this.blurOption,
    required this.brushOption,
    required this.emojiOption,
    required this.filtersOption,
    required this.flipOption,
    required this.rotateOption,
    required this.textOption,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Modifier Image'),
        ),
        body: Center(
          child: ImageEditor(
            image: image,
            cropOption: cropOption,
            blurOption: blurOption,
            brushOption: brushOption,
            emojiOption: emojiOption,
            filtersOption: filtersOption,
            flipOption: flipOption,
            rotateOption: rotateOption,
            textOption: textOption,
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            // Trigger the edit process and await the edited image
            final editedImage = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ImageEditor(
                  image: image,
                  cropOption: cropOption,
                  blurOption: blurOption,
                  brushOption: brushOption,
                  emojiOption: emojiOption,
                  filtersOption: filtersOption,
                  flipOption: flipOption,
                  rotateOption: rotateOption,
                  textOption: textOption,
                ),
              ),
            );
      
            // Return the edited image back to the previous screen
            if (editedImage != null) {
              Navigator.pop(context, editedImage);
            }
          },
          child: Icon(Icons.check),
        ),
      ),
    );
  }
}
