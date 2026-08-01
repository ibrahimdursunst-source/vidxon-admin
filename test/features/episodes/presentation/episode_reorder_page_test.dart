import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/content/data/content_errors.dart';
import 'package:vidxon_admin/features/episodes/domain/admin_episode.dart';
import 'package:vidxon_admin/features/episodes/presentation/episode_reorder_page.dart';
import 'package:vidxon_admin/features/episodes/presentation/episode_reorder_result.dart';
import 'package:vidxon_admin/features/series/domain/series_mutation_results.dart';

import '../../content/content_test_helpers.dart';

class _ReorderHost extends StatefulWidget {
  const _ReorderHost({
    required this.episodes,
    required this.mutationRepository,
    required this.episodeRepository,
  });

  final List<AdminEpisode> episodes;
  final TrackingSeriesMutationRepository mutationRepository;
  final FakeEpisodeRepository episodeRepository;

  @override
  State<_ReorderHost> createState() => _ReorderHostState();
}

class _ReorderHostState extends State<_ReorderHost> {
  int refreshCount = 0;
  EpisodeReorderPageResult? lastResult;
  int? lastSeriesVersion;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text('refresh:$refreshCount'),
          Text('version:${lastSeriesVersion ?? '-'}'),
          FilledButton(
            onPressed: () async {
              final result = await Navigator.of(context)
                  .push<EpisodeReorderPageResult>(
                    MaterialPageRoute(
                      builder: (context) => EpisodeReorderPage(
                        seriesId: testSeriesId,
                        episodes: widget.episodes,
                        expectedSeriesVersion: 7,
                        mutationRepository: widget.mutationRepository,
                      ),
                    ),
                  );

              if (!mounted) {
                return;
              }

              setState(() => lastResult = result);

              if (result == null) {
                return;
              }

              if (result is EpisodeReorderConflict) {
                setState(() => refreshCount += 1);
                return;
              }

              if (result is EpisodeReorderSuccess) {
                setState(() {
                  lastSeriesVersion = result.seriesContentVersion;
                  refreshCount += 1;
                });
              }
            },
            child: const Text('Open Reorder'),
          ),
        ],
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(configureContentWidgetTests);

  group('EpisodeReorderPage widget', () {
    Future<void> openReorder(WidgetTester tester) async {
      final episodes = [
        testEpisode(id: testEpisodeId1, episodeNumber: 1, title: 'Bir'),
        testEpisode(id: testEpisodeId2, episodeNumber: 2, title: 'İki'),
      ];
      final mutationRepository = TrackingSeriesMutationRepository();
      final episodeRepository = FakeEpisodeRepository(episodes);

      await tester.pumpWidget(
        MaterialApp(
          home: _ReorderHost(
            episodes: episodes,
            mutationRepository: mutationRepository,
            episodeRepository: episodeRepository,
          ),
        ),
      );
      await tester.tap(find.text('Open Reorder'));
      await tester.pumpAndSettle();
    }

    testWidgets('lists only provided non-archived episodes', (tester) async {
      await openReorder(tester);

      expect(find.text('#1 · Bir'), findsOneWidget);
      expect(find.text('#2 · İki'), findsOneWidget);
    });

    testWidgets('save disabled until order changes', (tester) async {
      await openReorder(tester);

      final saveButton = find.widgetWithText(FilledButton, 'Sıralamayı Kaydet');
      expect(tester.widget<FilledButton>(saveButton).onPressed, isNull);
    });

    testWidgets('cancel closes without repository call', (tester) async {
      final mutationRepository = TrackingSeriesMutationRepository();
      final episodes = [
        testEpisode(id: testEpisodeId1, episodeNumber: 1),
        testEpisode(id: testEpisodeId2, episodeNumber: 2),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: EpisodeReorderPage(
            seriesId: testSeriesId,
            episodes: episodes,
            expectedSeriesVersion: 3,
            mutationRepository: mutationRepository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();

      expect(mutationRepository.reorderCalls, 0);
    });

    testWidgets('save sends full episode id list with expected version', (
      tester,
    ) async {
      final mutationRepository = TrackingSeriesMutationRepository();
      final episodes = [
        testEpisode(id: testEpisodeId1, episodeNumber: 1, title: 'Bir'),
        testEpisode(id: testEpisodeId2, episodeNumber: 2, title: 'İki'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: EpisodeReorderPage(
            seriesId: testSeriesId,
            episodes: episodes,
            expectedSeriesVersion: 7,
            mutationRepository: mutationRepository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.longPress(find.byIcon(Icons.drag_handle).first);
      await tester.pumpAndSettle();
      await tester.drag(
        find.byIcon(Icons.drag_handle).first,
        const Offset(0, 80),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sıralamayı Kaydet'));
      await tester.pumpAndSettle();

      expect(mutationRepository.reorderCalls, 1);
      expect(mutationRepository.lastReorderExpectedVersion, 7);
      expect(mutationRepository.lastReorderEpisodeIds, [
        testEpisodeId1,
        testEpisodeId2,
      ]);
      expect(mutationRepository.lastReorderEpisodeIds!.toSet().length, 2);
    });

    testWidgets('success returns new series version to parent host', (
      tester,
    ) async {
      final mutationRepository = TrackingSeriesMutationRepository();
      final episodes = [
        testEpisode(id: testEpisodeId1, episodeNumber: 1, title: 'Bir'),
        testEpisode(id: testEpisodeId2, episodeNumber: 2, title: 'İki'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: _ReorderHost(
            episodes: episodes,
            mutationRepository: mutationRepository,
            episodeRepository: FakeEpisodeRepository(episodes),
          ),
        ),
      );

      await tester.tap(find.text('Open Reorder'));
      await tester.pumpAndSettle();

      await tester.longPress(find.byIcon(Icons.drag_handle).first);
      await tester.pumpAndSettle();
      await tester.drag(
        find.byIcon(Icons.drag_handle).first,
        const Offset(0, 80),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sıralamayı Kaydet'));
      await tester.pumpAndSettle();

      expect(find.text('version:8'), findsOneWidget);
      expect(find.text('refresh:1'), findsOneWidget);
    });

    testWidgets('conflict triggers parent refresh without success version', (
      tester,
    ) async {
      final mutationRepository = TrackingSeriesMutationRepository(
        reorderThrowsConflict: true,
      );
      final episodes = [
        testEpisode(id: testEpisodeId1, episodeNumber: 1, title: 'Bir'),
        testEpisode(id: testEpisodeId2, episodeNumber: 2, title: 'İki'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: _ReorderHost(
            episodes: episodes,
            mutationRepository: mutationRepository,
            episodeRepository: FakeEpisodeRepository(episodes),
          ),
        ),
      );

      await tester.tap(find.text('Open Reorder'));
      await tester.pumpAndSettle();

      await tester.longPress(find.byIcon(Icons.drag_handle).first);
      await tester.pumpAndSettle();
      await tester.drag(
        find.byIcon(Icons.drag_handle).first,
        const Offset(0, 80),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sıralamayı Kaydet'));
      await tester.pumpAndSettle();

      expect(find.text('refresh:1'), findsOneWidget);
      expect(find.text('version:-'), findsOneWidget);
      expect(find.text(ContentErrorMapper.conflictMessage), findsOneWidget);
    });
  });

  group('EpisodeReorderPageResult', () {
    test('success carries canonical series version', () {
      const result = EpisodeReorderSuccess(9);
      expect(result.seriesContentVersion, 9);
    });

    test('conflict is distinct from success', () {
      const conflict = EpisodeReorderConflict();
      const success = EpisodeReorderSuccess(2);

      expect(conflict, isA<EpisodeReorderPageResult>());
      expect(success, isA<EpisodeReorderPageResult>());
      expect(conflict, isNot(equals(success)));
    });
  });

  group('EpisodeReorderPage double submit', () {
    testWidgets('save disables button and ignores second tap', (tester) async {
      final mutationRepository = TrackingSeriesMutationRepository()
        ..reorderDelay = Completer<void>();
      final episodes = [
        testEpisode(id: testEpisodeId1, episodeNumber: 1, title: 'Bir'),
        testEpisode(id: testEpisodeId2, episodeNumber: 2, title: 'İki'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: EpisodeReorderPage(
            seriesId: testSeriesId,
            episodes: episodes,
            expectedSeriesVersion: 4,
            mutationRepository: mutationRepository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.longPress(find.byIcon(Icons.drag_handle).first);
      await tester.pumpAndSettle();
      await tester.drag(
        find.byIcon(Icons.drag_handle).first,
        const Offset(0, 80),
      );
      await tester.pumpAndSettle();

      final saveButton = find.byType(FilledButton);
      await tester.tap(saveButton);
      await tester.pump();

      expect(mutationRepository.reorderCalls, 1);

      await tester.tap(saveButton);
      await tester.pump();

      expect(mutationRepository.reorderCalls, 1);
      expect(tester.widget<FilledButton>(saveButton).onPressed, isNull);

      mutationRepository.reorderDelay!.complete();
      await tester.pumpAndSettle();

      expect(mutationRepository.reorderCalls, 1);
    });

    testWidgets('error reverts local order to initial sequence', (
      tester,
    ) async {
      final throwingRepository = _ErrorReorderRepository();
      final episodes = [
        testEpisode(id: testEpisodeId1, episodeNumber: 1, title: 'Bir'),
        testEpisode(id: testEpisodeId2, episodeNumber: 2, title: 'İki'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: EpisodeReorderPage(
            seriesId: testSeriesId,
            episodes: episodes,
            expectedSeriesVersion: 4,
            mutationRepository: throwingRepository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('#1 · Bir'), findsOneWidget);

      await tester.longPress(find.byIcon(Icons.drag_handle).first);
      await tester.pumpAndSettle();
      await tester.drag(
        find.byIcon(Icons.drag_handle).first,
        const Offset(0, 80),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sıralamayı Kaydet'));
      await tester.pumpAndSettle();

      expect(find.text('#1 · Bir'), findsOneWidget);
      expect(throwingRepository.reorderCalls, 1);
    });
  });
}

class _ErrorReorderRepository extends TrackingSeriesMutationRepository {
  @override
  Future<SeriesReorderResult> reorderEpisodes({
    required String seriesId,
    required List<String> orderedEpisodeIds,
    required int expectedSeriesVersion,
  }) async {
    reorderCalls += 1;
    throw const ContentException(
      message: 'Sıralama hatası',
      kind: ContentFailureKind.validation,
    );
  }
}
