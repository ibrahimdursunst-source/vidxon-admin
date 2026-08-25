import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/episodes/domain/admin_episode.dart';
import 'package:vidxon_admin/features/episodes/domain/cloudflare_stream_status.dart';
import 'package:vidxon_admin/features/episodes/presentation/series_episodes_page.dart';

import '../../content/content_test_helpers.dart';

void main() {
  group('episodeMenuLabels / publish visibility', () {
    test('unpublished + ready + eligible -> Publish visible and enabled', () {
      final episode = testEpisode(
        streamStatus: CloudflareStreamStatus.ready,
      );
      final labels = episodeMenuLabels(episode);
      final publish = episodeMenuPublishItem(episode);

      expect(labels, contains('Yayınla'));
      expect(publish, isNotNull);
      expect(publish!.enabled, isTrue);
      expect(episodeMenuPublishReason(episode), isNull);
    });

    test('unpublished + no video -> Publish visible, disabled, reason visible', () {
      final episode = testEpisode();
      final publish = episodeMenuPublishItem(episode);

      expect(episodeMenuLabels(episode), contains('Yayınla'));
      expect(publish, isNotNull);
      expect(publish!.enabled, isFalse);
      expect(
        episodeMenuPublishReason(episode),
        'Yayınlamak için aktif video gerekir.',
      );
    });

    test(
      'unpublished + video processing -> Publish visible, disabled, reason',
      () {
        final episode = testEpisode(
          streamStatus: CloudflareStreamStatus.processing,
        );
        final publish = episodeMenuPublishItem(episode);

        expect(episodeMenuLabels(episode), contains('Yayınla'));
        expect(publish!.enabled, isFalse);
        expect(episodeMenuPublishReason(episode), 'Video işleniyor.');
      },
    );

    test(
      'unpublished + video error -> Publish visible, disabled, reason',
      () {
        final episode = testEpisode(
          streamStatus: CloudflareStreamStatus.error,
        );
        final publish = episodeMenuPublishItem(episode);

        expect(episodeMenuLabels(episode), contains('Yayınla'));
        expect(publish!.enabled, isFalse);
        expect(
          episodeMenuPublishReason(episode),
          'Video hatası giderilmelidir.',
        );
      },
    );

    test(
      'paid + zero coin price -> Publish visible, disabled, pricing reason',
      () {
        final episode = testEpisode(
          streamStatus: CloudflareStreamStatus.ready,
          isFree: false,
          coinPrice: 0,
        );
        final publish = episodeMenuPublishItem(episode);

        expect(episodeMenuLabels(episode), contains('Yayınla'));
        expect(publish!.enabled, isFalse);
        expect(
          episodeMenuPublishReason(episode),
          'Ücretli bölümde coin fiyatı 0\'dan büyük olmalıdır.',
        );
      },
    );

    test(
      'parent series archived + episode unpublished -> Publish disabled',
      () {
        final episode = testEpisode(
          streamStatus: CloudflareStreamStatus.ready,
        );
        final publish = episodeMenuPublishItem(
          episode,
          parentSeriesArchived: true,
        );

        expect(
          episodeMenuLabels(episode, parentSeriesArchived: true),
          contains('Yayınla'),
        );
        expect(publish!.enabled, isFalse);
        expect(
          episodeMenuPublishReason(episode, parentSeriesArchived: true),
          AdminEpisode.parentSeriesArchivedPublishBlockReason,
        );
      },
    );

    test('published + active -> Unpublish visible, Publish absent', () {
      final episode = testEpisode(
        isPublished: true,
        streamStatus: CloudflareStreamStatus.ready,
      );
      final labels = episodeMenuLabels(episode);

      expect(labels, contains('Yayından Kaldır'));
      expect(labels, isNot(contains('Yayınla')));
      expect(episodeMenuPublishItem(episode), isNull);
    });

    test('archived episode -> Publish/Unpublish absent, Restore present', () {
      final labels = episodeMenuLabels(
        testEpisode(
          isArchived: true,
          streamStatus: CloudflareStreamStatus.ready,
        ),
      );

      expect(labels, contains('Geri Yükle'));
      expect(labels, isNot(contains('Yayınla')));
      expect(labels, isNot(contains('Yayından Kaldır')));
      expect(labels, isNot(contains('Arşivle')));
    });
  });
}
