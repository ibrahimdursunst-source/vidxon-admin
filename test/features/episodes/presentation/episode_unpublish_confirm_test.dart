import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/episodes/domain/cloudflare_stream_status.dart';
import 'package:vidxon_admin/features/episodes/presentation/series_episodes_page.dart';

import '../../content/content_test_helpers.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  while (tester.takeException() != null) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(configureContentWidgetTests);

  testWidgets('unpublish confirm uses updated Turkish copy', (tester) async {
    final repository = FakeEpisodeRepository([
      testEpisode(
        isPublished: true,
        streamStatus: CloudflareStreamStatus.ready,
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: SeriesEpisodesPage(
          seriesId: testSeriesId,
          seriesTitle: 'Test Dizi',
          episodeRepository: repository,
        ),
      ),
    );
    await _settle(tester);

    await tester.tap(find.byIcon(Icons.more_vert));
    await _settle(tester);
    await tester.tap(find.text('Yayından Kaldır'));
    await _settle(tester);

    expect(find.text('Bölümü Yayından Kaldır?'), findsOneWidget);
    expect(
      find.textContaining('erişilemez hâle gelecektir'),
      findsOneWidget,
    );
    expect(find.text('İptal'), findsOneWidget);
    expect(find.text('Yayından Kaldır'), findsWidgets);

    await tester.tap(find.text('İptal'));
    await _settle(tester);
    expect(repository.unpublishCalls, 0);
  });
}
