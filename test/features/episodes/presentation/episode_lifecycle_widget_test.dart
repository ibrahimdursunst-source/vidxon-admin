import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/episodes/domain/cloudflare_stream_status.dart';
import 'package:vidxon_admin/features/episodes/presentation/series_episodes_page.dart';

import '../../content/content_test_helpers.dart';

void main() {
  group('episodeMenuLabels', () {
    test('ready active video includes publish', () {
      final labels = episodeMenuLabels(
        testEpisode(
          streamUid: 'stream-1',
          streamStatus: CloudflareStreamStatus.ready,
        ),
      );

      expect(labels, contains('Yayınla'));
    });

    test('processing video excludes publish', () {
      final labels = episodeMenuLabels(
        testEpisode(
          streamUid: 'stream-1',
          streamStatus: CloudflareStreamStatus.processing,
        ),
      );

      expect(labels, isNot(contains('Yayınla')));
    });

    test('no video excludes publish', () {
      final labels = episodeMenuLabels(testEpisode());

      expect(labels, isNot(contains('Yayınla')));
    });

    test('archived episode shows only restore', () {
      final labels = episodeMenuLabels(
        testEpisode(
          isArchived: true,
          streamUid: 'stream-1',
          streamStatus: CloudflareStreamStatus.ready,
        ),
      );

      expect(labels, contains('Geri Yükle'));
      expect(labels, isNot(contains('Yayınla')));
      expect(labels, isNot(contains('Arşivle')));
    });

    test('archived parent series hides publish', () {
      final labels = episodeMenuLabels(
        testEpisode(
          streamUid: 'stream-1',
          streamStatus: CloudflareStreamStatus.ready,
        ),
        parentSeriesArchived: true,
      );

      expect(labels, isNot(contains('Yayınla')));
    });

    test('error video excludes publish', () {
      final labels = episodeMenuLabels(
        testEpisode(
          streamUid: 'stream-1',
          streamStatus: CloudflareStreamStatus.error,
        ),
      );

      expect(labels, isNot(contains('Yayınla')));
    });
  });
}
