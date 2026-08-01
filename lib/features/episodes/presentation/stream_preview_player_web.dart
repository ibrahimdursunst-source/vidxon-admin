// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

class StreamPreviewPlayer extends StatefulWidget {
  const StreamPreviewPlayer({required this.previewUrl, super.key});

  final String previewUrl;

  @override
  State<StreamPreviewPlayer> createState() => _StreamPreviewPlayerState();
}

class _StreamPreviewPlayerState extends State<StreamPreviewPlayer> {
  late final String _viewType;
  html.IFrameElement? _iframe;

  @override
  void initState() {
    super.initState();
    _viewType =
        'stream-preview-${identityHashCode(this)}-${DateTime.now().microsecondsSinceEpoch}';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final iframe = html.IFrameElement()
        ..src = widget.previewUrl
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allowFullscreen = true;
      _iframe = iframe;
      return iframe;
    });
  }

  @override
  void dispose() {
    final iframe = _iframe;
    if (iframe != null) {
      iframe.src = 'about:blank';
      iframe.remove();
      _iframe = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
