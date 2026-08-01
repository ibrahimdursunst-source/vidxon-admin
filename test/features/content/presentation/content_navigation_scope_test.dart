import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/admin_context/domain/admin_current_context.dart';
import 'package:vidxon_admin/features/admin_context/presentation/admin_context_scope.dart';
import 'package:vidxon_admin/features/admin_context/presentation/admin_root_navigator.dart';
import 'package:vidxon_admin/features/episodes/domain/cloudflare_stream_status.dart';
import 'package:vidxon_admin/features/episodes/presentation/episode_preview_dialog.dart';
import 'package:vidxon_admin/features/episodes/presentation/series_episodes_page.dart';
import 'package:vidxon_admin/features/series/presentation/series_detail_page.dart';

import '../content_test_helpers.dart';

AdminCurrentContext _adminContext() {
  return AdminCurrentContext.fromMap({
    'user_id': '11111111-1111-1111-1111-111111111111',
    'role': 'admin',
    'is_super_admin': false,
  });
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  while (tester.takeException() != null) {}
}

class _ContentNavigationHost extends StatelessWidget {
  const _ContentNavigationHost({
    required this.seriesRepository,
    required this.episodeRepository,
    required this.previewRepository,
  });

  final FakeSeriesRepository seriesRepository;
  final FakeEpisodeRepository episodeRepository;
  final FakeEpisodePreviewRepository previewRepository;

  @override
  Widget build(BuildContext context) {
    final contextResult = AdminContextScope.maybeOf(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Role:${contextResult?.context?.role ?? 'none'}'),
      ),
      body: Column(
        children: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) {
                    expect(AdminContextScope.maybeOf(context), isNotNull);
                    return SeriesDetailPage(
                      seriesId: testSeriesId,
                      seriesRepository: seriesRepository,
                      categoryRepository: FakeCategoryRepository(),
                      mutationRepository: FakeSeriesMutationRepository(),
                    );
                  },
                ),
              );
            },
            child: const Text('Open Detail'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) {
                    expect(AdminContextScope.maybeOf(context), isNotNull);
                    return SeriesEpisodesPage(
                      seriesId: testSeriesId,
                      seriesTitle: 'Test Dizi',
                      episodeRepository: episodeRepository,
                      previewRepository: previewRepository,
                    );
                  },
                ),
              );
            },
            child: const Text('Open Episodes'),
          ),
        ],
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(configureContentWidgetTests);

  group('Content navigation under AdminContextScope', () {
    Future<void> pumpHost(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final seriesRepository = FakeSeriesRepository((_) async => testSeries());
      final episodeRepository = FakeEpisodeRepository([
        testEpisode(
          streamUid: 'stream-1',
          streamStatus: CloudflareStreamStatus.ready,
        ),
      ]);
      final previewRepository = FakeEpisodePreviewRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: AdminContextScope(
            contextResult: AdminContextLoadResult.loaded(_adminContext()),
            child: Navigator(
              onGenerateRoute: (_) => MaterialPageRoute<void>(
                builder: (_) => _ContentNavigationHost(
                  seriesRepository: seriesRepository,
                  episodeRepository: episodeRepository,
                  previewRepository: previewRepository,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      while (tester.takeException() != null) {}
    }

    testWidgets('series detail route keeps AdminContextScope accessible', (
      tester,
    ) async {
      await pumpHost(tester);

      await tester.tap(find.text('Open Detail'));
      await tester.pumpAndSettle();
      while (tester.takeException() != null) {}

      await tester.ensureVisible(find.text('Yayınla'));
      expect(find.text('Yayınla'), findsOneWidget);
    });

    testWidgets('episode list route keeps AdminContextScope accessible', (
      tester,
    ) async {
      await pumpHost(tester);

      await tester.tap(find.text('Open Episodes'));
      await _settle(tester);

      expect(find.text('Yeni Bölüm'), findsOneWidget);
      expect(
        AdminContextScope.maybeOf(tester.element(find.text('Yeni Bölüm'))),
        isNotNull,
      );
    });

    testWidgets('app back returns to parent route', (tester) async {
      await pumpHost(tester);

      await tester.tap(find.text('Open Detail'));
      await tester.pumpAndSettle();
      while (tester.takeException() != null) {}

      final backButton = find.byType(BackButton);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
      } else {
        await tester.pageBack();
      }
      await tester.pumpAndSettle();
      while (tester.takeException() != null) {}

      expect(find.text('Open Detail'), findsOneWidget);
      expect(find.text('Open Episodes'), findsOneWidget);
    });

    testWidgets('preview dialog cancel does not imply success refresh', (
      tester,
    ) async {
      final previewRepository = FakeEpisodePreviewRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: AdminContextScope(
            contextResult: AdminContextLoadResult.loaded(_adminContext()),
            child: Scaffold(
              body: Builder(
                builder: (context) {
                  return FilledButton(
                    onPressed: () {
                      showEpisodePreviewDialog(
                        context: context,
                        episode: testEpisode(
                          streamUid: 'stream-1',
                          streamStatus: CloudflareStreamStatus.ready,
                        ),
                        videoSource: 'active',
                        repository: previewRepository,
                      );
                    },
                    child: const Text('Preview'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Preview'));
      await _settle(tester);
      expect(previewRepository.callCount, 1);

      await tester.tap(find.text('Kapat'));
      await _settle(tester);

      expect(previewRepository.callCount, 1);
      expect(find.text('Dizi başarıyla oluşturuldu.'), findsNothing);
    });
  });

  testWidgets('AdminRootNavigator remains nested navigator widget', (
    tester,
  ) async {
    const navigator = AdminRootNavigator(email: 'actor@example.com');
    expect(navigator, isA<StatelessWidget>());
  });

  group('Episode list to reorder navigation', () {
    Future<void> pumpReorderHost(
      WidgetTester tester, {
      required TrackingSeriesMutationRepository mutationRepository,
      required FakeEpisodeRepository episodeRepository,
    }) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: AdminContextScope(
            contextResult: AdminContextLoadResult.loaded(_adminContext()),
            child: Navigator(
              onGenerateRoute: (_) => MaterialPageRoute<void>(
                builder: (_) => SeriesEpisodesPage(
                  seriesId: testSeriesId,
                  seriesTitle: 'Test Dizi',
                  initialSeries: testSeries(contentVersion: 7),
                  episodeRepository: episodeRepository,
                  mutationRepository: mutationRepository,
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
    }

    Future<void> openReorder(WidgetTester tester) async {
      await tester.tap(find.text('Sıralamayı Düzenle'));
      await _settle(tester);
      expect(find.text('Bölüm Sıralaması'), findsOneWidget);
      expect(
        AdminContextScope.maybeOf(
          tester.element(find.text('Bölüm Sıralaması')),
        ),
        isNotNull,
      );
    }

    testWidgets('opens reorder from episode list and returns on app back', (
      tester,
    ) async {
      final mutationRepository = TrackingSeriesMutationRepository();
      final episodeRepository = FakeEpisodeRepository([
        testEpisode(id: testEpisodeId1, episodeNumber: 1, title: 'Bir'),
        testEpisode(id: testEpisodeId2, episodeNumber: 2, title: 'İki'),
      ]);

      await pumpReorderHost(
        tester,
        mutationRepository: mutationRepository,
        episodeRepository: episodeRepository,
      );
      await openReorder(tester);

      await tester.pageBack();
      await _settle(tester);

      expect(find.text('Bölümler'), findsOneWidget);
      expect(mutationRepository.reorderCalls, 0);
    });

    testWidgets('save success returns version and refreshes parent list', (
      tester,
    ) async {
      final mutationRepository = TrackingSeriesMutationRepository();
      final episodeRepository = FakeEpisodeRepository([
        testEpisode(id: testEpisodeId1, episodeNumber: 1, title: 'Bir'),
        testEpisode(id: testEpisodeId2, episodeNumber: 2, title: 'İki'),
      ]);

      await pumpReorderHost(
        tester,
        mutationRepository: mutationRepository,
        episodeRepository: episodeRepository,
      );
      final initialFetchCalls = episodeRepository.fetchListCalls;

      await openReorder(tester);

      await tester.longPress(find.byIcon(Icons.drag_handle).first);
      await _settle(tester);
      await tester.drag(
        find.byIcon(Icons.drag_handle).first,
        const Offset(0, 80),
      );
      await _settle(tester);
      await tester.tap(find.text('Sıralamayı Kaydet'));
      await _settle(tester);

      expect(mutationRepository.reorderCalls, 1);
      expect(mutationRepository.lastReorderExpectedVersion, 7);
      expect(episodeRepository.fetchListCalls, greaterThan(initialFetchCalls));
      expect(find.text('Bölümler'), findsOneWidget);
    });

    testWidgets('conflict refreshes parent without success version', (
      tester,
    ) async {
      final mutationRepository = TrackingSeriesMutationRepository(
        reorderThrowsConflict: true,
      );
      final episodeRepository = FakeEpisodeRepository([
        testEpisode(id: testEpisodeId1, episodeNumber: 1, title: 'Bir'),
        testEpisode(id: testEpisodeId2, episodeNumber: 2, title: 'İki'),
      ]);

      await pumpReorderHost(
        tester,
        mutationRepository: mutationRepository,
        episodeRepository: episodeRepository,
      );
      final initialFetchCalls = episodeRepository.fetchListCalls;

      await openReorder(tester);
      await tester.longPress(find.byIcon(Icons.drag_handle).first);
      await _settle(tester);
      await tester.drag(
        find.byIcon(Icons.drag_handle).first,
        const Offset(0, 80),
      );
      await _settle(tester);
      await tester.tap(find.text('Sıralamayı Kaydet'));
      await _settle(tester);

      expect(episodeRepository.fetchListCalls, greaterThan(initialFetchCalls));
      expect(find.text('Bölümler'), findsOneWidget);
    });

    testWidgets('cancel does not mutate or refresh as success', (tester) async {
      final mutationRepository = TrackingSeriesMutationRepository();
      final episodeRepository = FakeEpisodeRepository([
        testEpisode(id: testEpisodeId1, episodeNumber: 1, title: 'Bir'),
        testEpisode(id: testEpisodeId2, episodeNumber: 2, title: 'İki'),
      ]);

      await pumpReorderHost(
        tester,
        mutationRepository: mutationRepository,
        episodeRepository: episodeRepository,
      );
      final initialFetchCalls = episodeRepository.fetchListCalls;

      await openReorder(tester);
      await tester.tap(find.text('Vazgeç'));
      await _settle(tester);

      expect(mutationRepository.reorderCalls, 0);
      expect(episodeRepository.fetchListCalls, initialFetchCalls);
      expect(find.text('Bölümler'), findsOneWidget);
    });
  });
}
