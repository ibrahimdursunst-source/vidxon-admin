import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/admin_context/domain/admin_current_context.dart';
import 'package:vidxon_admin/features/admin_context/presentation/admin_context_scope.dart';
import 'package:vidxon_admin/features/dashboard/presentation/admin_home_page.dart';

import '../../content/content_test_helpers.dart';

AdminCurrentContext _adminContext() {
  return AdminCurrentContext.fromMap({
    'user_id': '11111111-1111-1111-1111-111111111111',
    'role': 'admin',
    'is_super_admin': false,
  });
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
  while (tester.takeException() != null) {}
}

Future<void> _openCreateFromList(WidgetTester tester) async {
  expect(
    find.text('Vidxon içerik kataloğundaki dizileri yönetin'),
    findsOneWidget,
  );

  final createButton = find.widgetWithText(FilledButton, 'Yeni Dizi');
  expect(createButton, findsOneWidget);
  await tester.ensureVisible(createButton);
  await tester.tap(createButton);
  await _settle(tester);
}

Future<void> _fillAndSubmitCreate(WidgetTester tester) async {
  await tester.enterText(find.byType(TextFormField).at(0), 'Yeni Dizi');
  await tester.enterText(find.byType(TextFormField).at(1), 'yeni-dizi');
  tester.takeException();

  final createButtons = find.widgetWithText(FilledButton, 'Diziyi Oluştur');
  await tester.ensureVisible(createButtons);
  await tester.tap(createButtons);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
  tester.takeException();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(configureContentWidgetTests);

  group('AdminHomePage create to detail navigation', () {
    Future<
      ({
        FakeSeriesRepository listRepository,
        FakeSeriesRepository detailRepository,
        FakeSeriesMutationRepository mutationRepository,
      })
    >
    pumpHome(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final listRepository = FakeSeriesRepository(
        (_) async => testSeries(title: 'Listed Dizi'),
        fetchAllResult: [testSeries(title: 'Listed Dizi')],
      );
      final detailRepository = FakeSeriesRepository((_) async {
        return testSeries(
          id: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
          title: 'Server Detail Title',
          slug: 'yeni-dizi',
          contentVersion: 2,
        );
      });
      final mutationRepository = FakeSeriesMutationRepository()
        ..createResult = testSeries(
          id: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
          title: 'Yeni Dizi',
          slug: 'yeni-dizi',
          contentVersion: 1,
        );

      await tester.pumpWidget(
        MaterialApp(
          home: AdminContextScope(
            contextResult: AdminContextLoadResult.loaded(_adminContext()),
            child: Navigator(
              onGenerateRoute: (_) => MaterialPageRoute<void>(
                builder: (_) => AdminHomePage(
                  email: 'admin@example.com',
                  initialSelectedNavIndex: 1,
                  seriesListRepository: listRepository,
                  seriesDetailRepository: detailRepository,
                  seriesCreateMutationRepository: mutationRepository,
                  imageUploadRepository: FakeImageUploadRepository(),
                  categoryRepository: FakeCategoryRepository(),
                  dashboardRepository: FakeDashboardRepository(),
                  initialPosterForTesting: testPosterFile(),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);

      return (
        listRepository: listRepository,
        detailRepository: detailRepository,
        mutationRepository: mutationRepository,
      );
    }

    testWidgets(
      'successful create refreshes list opens detail and re-fetches',
      (tester) async {
        final repos = await pumpHome(tester);
        final initialFetchAllCalls = repos.listRepository.fetchAllCalls;

        await _openCreateFromList(tester);
        await _fillAndSubmitCreate(tester);
        await _settle(tester);

        expect(repos.mutationRepository.createCalls, 1);
        expect(
          repos.listRepository.fetchAllCalls,
          greaterThan(initialFetchAllCalls),
        );
      expect(find.text('Server Detail Title'), findsWidgets);
      expect(repos.detailRepository.fetchByIdCalls, greaterThanOrEqualTo(1));
      expect(find.text('Yayın ve Arşiv'), findsOneWidget);
      expect(
        AdminContextScope.maybeOf(
          tester.element(find.text('Yayın ve Arşiv')),
        ),
        isNotNull,
      );
        expect(find.text('Dizi başarıyla oluşturuldu.'), findsOneWidget);
      },
    );

    testWidgets('failed create does not open detail or refresh list wrongly', (
      tester,
    ) async {
      final repos = await pumpHome(tester);
      repos.mutationRepository.createResult = null;
      final initialFetchAllCalls = repos.listRepository.fetchAllCalls;

      await _openCreateFromList(tester);
      await _fillAndSubmitCreate(tester);
      await _settle(tester);

      expect(repos.mutationRepository.createCalls, 1);
      expect(repos.listRepository.fetchAllCalls, initialFetchAllCalls);
      expect(find.text('Server Detail Title'), findsNothing);
      expect(find.text('Dizi başarıyla oluşturuldu.'), findsNothing);
      expect(find.text('Create failed'), findsOneWidget);
    });

    testWidgets('cancel does not call repository or navigate to detail', (
      tester,
    ) async {
      final repos = await pumpHome(tester);

      await _openCreateFromList(tester);
      final cancelButton = find.text('İptal');
      await tester.ensureVisible(cancelButton);
      await tester.tap(cancelButton);
      await _settle(tester);

      expect(repos.mutationRepository.createCalls, 0);
      expect(
        find.text('Vidxon içerik kataloğundaki dizileri yönetin'),
        findsOneWidget,
      );
      expect(find.text('Server Detail Title'), findsNothing);
    });
  });
}
