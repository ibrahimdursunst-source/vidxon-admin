import 'dart:async';

class UploadProgressTracker {
  UploadProgressTracker({
    required this.totalBytes,
    this.minProgressDelta = 0.01,
    this._onProgress,
  });

  final int totalBytes;
  final double minProgressDelta;
  final void Function(double progress)? _onProgress;

  int _sentBytes = 0;
  double _lastReportedProgress = 0;

  Stream<List<int>> wrap(Stream<List<int>> source) async* {
    await for (final chunk in source) {
      _sentBytes += chunk.length;
      _emitProgress();
      yield chunk;
    }

    _sentBytes = totalBytes;
    _emitProgress(force: true);
  }

  void _emitProgress({bool force = false}) {
    if (totalBytes <= 0) {
      return;
    }

    final progress = (_sentBytes / totalBytes).clamp(0.0, 1.0);
    if (!force && (progress - _lastReportedProgress) < minProgressDelta) {
      return;
    }

    _lastReportedProgress = progress;
    _onProgress?.call(progress);
  }
}

double calculateUploadProgress({
  required int sentBytes,
  required int totalBytes,
}) {
  if (totalBytes <= 0) {
    return 0;
  }

  return (sentBytes / totalBytes).clamp(0.0, 1.0);
}
