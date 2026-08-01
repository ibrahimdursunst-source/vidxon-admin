import 'package:flutter/material.dart';

class StreamPreviewPlayer extends StatelessWidget {
  const StreamPreviewPlayer({required this.previewUrl, super.key});

  final String previewUrl;

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Video önizleme yalnızca web ortamında desteklenir.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFFB3B3B3)),
      ),
    );
  }
}
