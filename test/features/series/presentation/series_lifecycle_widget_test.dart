import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/series/presentation/series_detail_page.dart';

import '../../content/content_test_helpers.dart';

void main() {
  group('seriesLifecycleActionLabels', () {
    test('unpublished shows publish and archive', () {
      expect(seriesLifecycleActionLabels(testSeries(isPublished: false)), [
        'Yayınla',
        'Arşivle',
      ]);
    });

    test('published shows unpublish and archive', () {
      expect(seriesLifecycleActionLabels(testSeries(isPublished: true)), [
        'Yayından Kaldır',
        'Arşivle',
      ]);
    });

    test('archived shows only restore', () {
      expect(
        seriesLifecycleActionLabels(
          testSeries(isPublished: true, isArchived: true),
        ),
        ['Geri Yükle'],
      );
    });

    test('restored state is not published by default', () {
      final labels = seriesLifecycleActionLabels(
        testSeries(isPublished: false, isArchived: false),
      );

      expect(labels, contains('Yayınla'));
      expect(labels, isNot(contains('Yayından Kaldır')));
    });
  });
}
