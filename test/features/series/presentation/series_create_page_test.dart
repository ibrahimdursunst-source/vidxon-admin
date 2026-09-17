import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/media/data/image_upload_repository.dart';
import 'package:vidxon_admin/features/series/domain/admin_series.dart';
import 'package:vidxon_admin/features/series/domain/create_series_input.dart';
import 'package:vidxon_admin/features/series/presentation/series_create_page.dart';

import '../../content/content_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(configureContentWidgetTests);

  group('SeriesCreatePage', () {
    Future<void> pumpCreate(
      WidgetTester tester, {
      required FakeSeriesMutationRepository mutationRepository,
      FakeImageUploadRepository? imageUploadRepository,
      void Function(AdminSeries created)? onSuccess,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeriesCreatePage(
              onCancel: () {},
              onSuccess: onSuccess ?? (_) {},
              seriesMutationRepository: mutationRepository,
              imageUploadRepository:
                  imageUploadRepository ?? FakeImageUploadRepository(),
              categoryRepository: FakeCategoryRepository(),
              initialPosterForTesting: testPosterFile(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'Yeni Dizi');
      await tester.enterText(find.byType(TextFormField).at(2), 'yeni-dizi');
      tester.takeException();
    }

    Future<void> tapCreate(WidgetTester tester) async {
      final button = find.text('Diziyi Oluştur');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      tester.takeException();
    }

    Future<void> waitForCreate(WidgetTester tester) async {
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      tester.takeException();
    }

    testWidgets('create sends unpublished flag and returns canonical result', (
      tester,
    ) async {
      final mutationRepository = FakeSeriesMutationRepository()
        ..createResult = testSeries(title: 'Yeni Dizi', slug: 'yeni-dizi');
      AdminSeries? created;

      await pumpCreate(
        tester,
        mutationRepository: mutationRepository,
        onSuccess: (result) => created = result,
      );

      await tapCreate(tester);
      await waitForCreate(tester);

      expect(mutationRepository.createCalls, 1);
      expect(
        buildCreateSeriesRpcParams(
          mutationRepository.lastCreateInput!,
        )['p_is_published'],
        isFalse,
      );
      expect(created, isNotNull);
      expect(created!.title, 'Yeni Dizi');
    });

    testWidgets(
      'unmapped portrait upload transport error shows generic unexpectedRetry',
      (tester) async {
        final mutationRepository = FakeSeriesMutationRepository()
          ..createResult = testSeries();
        final imageUploadRepository = FakeImageUploadRepository()
          ..requestError = Exception('Failed to fetch');

        await pumpCreate(
          tester,
          mutationRepository: mutationRepository,
          imageUploadRepository: imageUploadRepository,
        );
        await tapCreate(tester);

        expect(mutationRepository.createCalls, 0);
        expect(
          find.text('Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'mapped portrait upload failure shows stable upload message',
      (tester) async {
        final mutationRepository = FakeSeriesMutationRepository()
          ..createResult = testSeries();
        final imageUploadRepository = FakeImageUploadRepository()
          ..requestError = ImageUploadException(imageUploadUrlFailedMessage);

        await pumpCreate(
          tester,
          mutationRepository: mutationRepository,
          imageUploadRepository: imageUploadRepository,
        );
        await tapCreate(tester);

        expect(mutationRepository.createCalls, 0);
        expect(find.text(imageUploadUrlFailedMessage), findsOneWidget);
        expect(
          find.text('Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.'),
          findsNothing,
        );
      },
    );

    testWidgets('failure does not invoke success callback', (tester) async {
      var successCalled = false;
      final mutationRepository = FakeSeriesMutationRepository();

      await pumpCreate(
        tester,
        mutationRepository: mutationRepository,
        onSuccess: (_) => successCalled = true,
      );

      await tapCreate(tester);

      expect(successCalled, isFalse);
      expect(find.text('Dizi başarıyla oluşturuldu.'), findsNothing);
    });

    testWidgets('cancel does not call create repository', (tester) async {
      final mutationRepository = FakeSeriesMutationRepository()
        ..createResult = testSeries();

      await pumpCreate(tester, mutationRepository: mutationRepository);
      await tester.tap(find.text('İptal'));
      await tester.pumpAndSettle();

      expect(mutationRepository.createCalls, 0);
    });

    testWidgets('double submit triggers create only once', (tester) async {
      final mutationRepository = FakeSeriesMutationRepository()
        ..createResult = testSeries(title: 'Yeni Dizi');

      await pumpCreate(tester, mutationRepository: mutationRepository);

      final button = find.byType(FilledButton);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();

      expect(tester.widget<FilledButton>(button).onPressed, isNull);

      await tester.tap(button);
      await tester.pump();

      await waitForCreate(tester);

      expect(mutationRepository.createCalls, 1);
    });
  });
}
