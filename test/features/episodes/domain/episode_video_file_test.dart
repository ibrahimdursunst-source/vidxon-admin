import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/episodes/domain/episode_video_file.dart';

Stream<List<int>> _streamFromBytes(List<int> bytes) async* {
  yield bytes;
}

void main() {
  group('EpisodeVideoFileValidator', () {
    test('accepts valid MP4 file', () {
      final file = EpisodeVideoFileValidator.validate(
        name: 'episode-1.mp4',
        size: 1024,
        contentType: 'video/mp4',
        readStream: _streamFromBytes([1, 2, 3]),
      );

      expect(file.name, 'episode-1.mp4');
      expect(file.extension, 'mp4');
      expect(file.contentType, 'video/mp4');
    });

    test('rejects non-mp4 extension', () {
      expect(
        () => EpisodeVideoFileValidator.validate(
          name: 'episode-1.webm',
          size: 1024,
          contentType: 'video/mp4',
          readStream: _streamFromBytes([1]),
        ),
        throwsA(isA<EpisodeVideoFileValidationException>()),
      );
    });

    test('rejects wrong MIME type', () {
      expect(
        () => EpisodeVideoFileValidator.validate(
          name: 'episode-1.mp4',
          size: 1024,
          contentType: 'video/webm',
          readStream: _streamFromBytes([1]),
        ),
        throwsA(isA<EpisodeVideoFileValidationException>()),
      );
    });

    test('rejects zero size', () {
      expect(
        () => EpisodeVideoFileValidator.validate(
          name: 'episode-1.mp4',
          size: 0,
          contentType: 'video/mp4',
          readStream: _streamFromBytes([]),
        ),
        throwsA(isA<EpisodeVideoFileValidationException>()),
      );
    });

    test('rejects file above size limit', () {
      expect(
        () => EpisodeVideoFileValidator.validate(
          name: 'episode-1.mp4',
          size: EpisodeVideoFile.maxSizeBytes + 1,
          contentType: 'video/mp4',
          readStream: _streamFromBytes([1]),
        ),
        throwsA(isA<EpisodeVideoFileValidationException>()),
      );
    });

    test(
      'readStream can be consumed without loading entire file into memory',
      () async {
        final chunks = <List<int>>[];
        final controller = StreamController<List<int>>();

        final file = EpisodeVideoFileValidator.validate(
          name: 'episode-1.mp4',
          size: 6,
          contentType: 'video/mp4',
          readStream: controller.stream,
        );

        final subscription = file.readStream.listen(chunks.add);
        controller
          ..add([1, 2])
          ..add([3, 4, 5, 6]);
        await controller.close();
        await subscription.cancel();

        expect(chunks, [
          [1, 2],
          [3, 4, 5, 6],
        ]);
      },
    );
  });
}
