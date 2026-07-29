import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/episodes/data/upload_progress.dart';

void main() {
  group('calculateUploadProgress', () {
    test('returns ratio clamped between 0 and 1', () {
      expect(calculateUploadProgress(sentBytes: 50, totalBytes: 100), 0.5);
      expect(calculateUploadProgress(sentBytes: 150, totalBytes: 100), 1);
      expect(calculateUploadProgress(sentBytes: 0, totalBytes: 0), 0);
    });
  });

  group('UploadProgressTracker', () {
    test('tracks sent file bytes without boundary overhead', () async {
      final progressValues = <double>[];
      final tracker = UploadProgressTracker(
        totalBytes: 10,
        minProgressDelta: 0.1,
        onProgress: progressValues.add,
      );

      final source = Stream<List<int>>.fromIterable([
        [1, 2, 3],
        [4, 5, 6, 7],
        [8, 9, 10],
      ]);

      await tracker.wrap(source).drain();

      expect(progressValues.isNotEmpty, isTrue);
      expect(progressValues.last, 1);
    });
  });
}
