import 'package:flutter/material.dart';

/// Compact synopsis under a list title. Renders nothing when empty/blank.
class SynopsisPreview extends StatelessWidget {
  const SynopsisPreview({
    required this.synopsis,
    this.maxLines = 3,
    super.key,
  });

  final String synopsis;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final text = synopsis.trim();
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFFB3B3B3),
          fontSize: 12,
          height: 1.35,
        ),
      ),
    );
  }
}
