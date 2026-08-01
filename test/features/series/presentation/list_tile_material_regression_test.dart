import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/episodes/presentation/episode_reorder_page.dart';
import 'package:vidxon_admin/features/series/presentation/series_create_page.dart';
import 'package:vidxon_admin/features/series/presentation/series_detail_page.dart';

import '../../content/content_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(configureContentWidgetTests);

  group('ListTile Material regression', () {
    void expectNoListTileAssertion(WidgetTester tester) {
      final exception = tester.takeException();
      if (exception == null) {
        return;
      }

      expect(
        exception.toString(),
        isNot(
          contains(
            'ListTile background color or ink splashes may be invisible',
          ),
        ),
      );
    }

    Finder materialCardAncestor(Finder tileFinder) {
      return find.ancestor(
        of: tileFinder,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Material && widget.color == const Color(0xFF111111),
        ),
      );
    }

    testWidgets(
      'SeriesCreatePage switches render under Material without assertion',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1200, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SeriesCreatePage(
                onCancel: () {},
                onSuccess: (_) {},
                seriesMutationRepository: FakeSeriesMutationRepository(),
                imageUploadRepository: FakeImageUploadRepository(),
                categoryRepository: FakeCategoryRepository(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expectNoListTileAssertion(tester);

        final switchTile = find.byType(SwitchListTile).first;
        expect(materialCardAncestor(switchTile), findsWidgets);

        await tester.tap(switchTile);
        await tester.pump();
        expectNoListTileAssertion(tester);
      },
    );

    testWidgets(
      'SeriesDetailPage edit switches render under Material without assertion',
      (tester) async {
        addTearDown(() => tester.binding.setSurfaceSize(null));

        for (final width in [400.0, 1200.0]) {
          await tester.binding.setSurfaceSize(Size(width, 900));
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SeriesDetailPage(
                  seriesId: testSeriesId,
                  seriesRepository: FakeSeriesRepository(
                    (_) async => testSeries(contentVersion: 1),
                  ),
                  mutationRepository: FakeSeriesMutationRepository(),
                  categoryRepository: FakeCategoryRepository(),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expectNoListTileAssertion(tester);

          final switchTile = find.byType(SwitchListTile).first;
          expect(materialCardAncestor(switchTile), findsWidgets);
        }
      },
    );

    testWidgets(
      'EpisodeReorderPage list tiles render under Material without assertion',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: EpisodeReorderPage(
              seriesId: testSeriesId,
              episodes: [
                testEpisode(id: testEpisodeId1, episodeNumber: 1, title: 'Bir'),
                testEpisode(id: testEpisodeId2, episodeNumber: 2, title: 'İki'),
              ],
              expectedSeriesVersion: 1,
              mutationRepository: FakeSeriesMutationRepository(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expectNoListTileAssertion(tester);

        final listTile = find.byType(ListTile).first;
        expect(materialCardAncestor(listTile), findsOneWidget);
      },
    );
  });
}
