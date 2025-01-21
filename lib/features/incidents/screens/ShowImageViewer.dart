import 'package:flutter/material.dart';

class ShowImageViewer extends StatelessWidget {
  final String imageUrl;

  const ShowImageViewer({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Viewer'),
      ),
      body: Center(
        child: Image.network(
          imageUrl,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Text('Failed to load image');
          },
        ),
      ),
    );
  }
}
