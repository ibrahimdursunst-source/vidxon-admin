import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/content/data/content_errors.dart';
import 'package:vidxon_admin/features/episodes/presentation/episode_form_page.dart';
import 'package:vidxon_admin/features/series/domain/series_mutation_results.dart';

import '../../content/content_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(configureContentWidgetTests);

  test('episode editor save uses only the atomic translations RPC', () {
    final source = File(
      'lib/features/episodes/presentation/episode_form_page.dart',
    ).readAsStringSync();

    expect(source.contains('createEpisodeWithTranslations('), isTrue);
    expect(source.contains('updateEpisodeWithTranslations('), isTrue);
    expect(source.contains('upsertEpisodeTranslations('), isFalse);
  });

  test('episode atomic parser rejects ok=false and missing content_version', () {
    expect(parseRpcRow({'ok': false, 'episode_id': testEpisodeId1}), isNull);
    expect(
      () => requireContentVersion(null),
      throwsFormatException,
    );
  });

  testWidgets('failed episode atomic save does not show success snackbar', (
    tester,
  ) async {
    final repository = FakeEpisodeRepository([testEpisode(contentVersion: 2)])
      ..saveError = const ContentException(
        message: 'Çeviri dili geçersiz.',
        kind: ContentFailureKind.validation,
      );

    await tester.pumpWidget(
      MaterialApp(
        home: EpisodeFormPage(
          seriesId: testSeriesId,
          episode: testEpisode(contentVersion: 2),
          repository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();
    tester.takeException();

    await tester.ensureVisible(find.text('Güncelle'));
    await tester.tap(find.text('Güncelle'));
    await tester.pumpAndSettle();
    tester.takeException();

    expect(repository.updateCalls, 1);
    expect(find.text('Bölüm başarıyla güncellendi.'), findsNothing);
    expect(find.text('Çeviri dili geçersiz.'), findsWidgets);
  });

  testWidgets('malformed episode result does not show success snackbar', (
    tester,
  ) async {
    final repository = FakeEpisodeRepository([testEpisode(contentVersion: 2)])
      ..saveError = const ContentException(
        message: 'Bölüm yanıtı geçersiz.',
        kind: ContentFailureKind.serverError,
      );

    await tester.pumpWidget(
      MaterialApp(
        home: EpisodeFormPage(
          seriesId: testSeriesId,
          episode: testEpisode(contentVersion: 2),
          repository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();
    tester.takeException();

    await tester.ensureVisible(find.text('Güncelle'));
    await tester.tap(find.text('Güncelle'));
    await tester.pumpAndSettle();
    tester.takeException();

    expect(find.text('Bölüm başarıyla güncellendi.'), findsNothing);
    expect(find.text('Bölüm yanıtı geçersiz.'), findsWidgets);
  });
}
