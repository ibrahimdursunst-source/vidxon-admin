import 'package:flutter/material.dart';

import '../../../l10n/admin_l10n.dart';

class StreamPreviewPlayer extends StatelessWidget {
  const StreamPreviewPlayer({required this.previewUrl, super.key});

  final String previewUrl;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        context.l10n.previewWebOnly,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFFB3B3B3)),
      ),
    );
  }
}
