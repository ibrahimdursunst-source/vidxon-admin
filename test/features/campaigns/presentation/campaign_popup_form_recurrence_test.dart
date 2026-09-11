import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/campaigns/application/campaign_image_controller.dart';
import 'package:vidxon_admin/features/campaigns/application/popup_image_dimensions.dart';
import 'package:vidxon_admin/features/campaigns/data/campaign_repository.dart';
import 'package:vidxon_admin/features/campaigns/domain/admin_campaign.dart';
import 'package:vidxon_admin/features/campaigns/domain/campaign_display_mode.dart';
import 'package:vidxon_admin/features/campaigns/presentation/popup_campaign_form_dialog.dart';
import 'package:vidxon_admin/features/users/data/admin_user_wallet_repository.dart';
import 'package:vidxon_admin/features/users/domain/admin_user_summary.dart';
import 'package:vidxon_admin/l10n/admin_l10n.dart';

import '../../content/content_test_helpers.dart';

const _testUserId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';

final Uint8List kTinyPng = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE, 0x00, 0x00, 0x00,
  0x0C, 0x49, 0x44, 0x41, 0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
  0x00, 0x00, 0x03, 0x00, 0x01, 0x00, 0x05, 0xFE, 0xD4, 0xEF, 0x00, 0x00,
  0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

class _FakeCampaigns extends CampaignRepository {
  _FakeCampaigns() : super(client: null);

  int upsertCalls = 0;
  String? lastDisplayMode;
  String? lastDestinationType;
  bool? lastTestOnly;
  String? lastTestUserId;
  List<AdminCampaignTranslation> lastTranslations = const [];

  @override
  Future<AdminCampaign> upsert({
    String? id,
    String imagePath = '',
    String destinationType = 'none',
    String? destinationSeriesId,
    String? destinationEpisodeId,
    List<String> targetLocales = const [],
    bool isActive = false,
    int priority = 0,
    required DateTime startsAt,
    DateTime? endsAt,
    required List<AdminCampaignTranslation> translations,
    bool testOnly = false,
    String? testUserId,
    String displayMode = 'once',
  }) async {
    upsertCalls += 1;
    lastDisplayMode = displayMode;
    lastDestinationType = destinationType;
    lastTestOnly = testOnly;
    lastTestUserId = testUserId;
    lastTranslations = translations;
    return AdminCampaign(
      id: id ?? 'camp-1',
      imagePath: imagePath,
      destinationType: destinationType,
      targetLocales: targetLocales,
      isActive: isActive,
      priority: priority,
      startsAt: startsAt,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      translations: translations,
      testOnly: testOnly,
      testUserId: testUserId,
      displayMode: displayMode,
    );
  }
}

class _FakeUsers extends AdminUserWalletRepository {
  _FakeUsers() : super(client: null);

  @override
  Future<List<AdminUserSummary>> searchUsers({
    String query = '',
    int limit = 50,
    int offset = 0,
  }) async {
    return [
      AdminUserSummary.fromMap({
        'user_id': _testUserId,
        'email': 'qa@vidxon.test',
        'display_name': 'QA User',
        'account_status': 'active',
        'coin_balance': 0,
        'account_created_at': '2026-07-27T17:14:20.106837+00:00',
        'admin_role': null,
        'wallet_actions_allowed': true,
      }),
    ];
  }
}

AdminCampaign _existing({String displayMode = 'once'}) {
  return AdminCampaign(
    id: 'camp-edit',
    imagePath: 'campaigns/2026/09/old.png',
    destinationType: 'none',
    targetLocales: const ['tr'],
    isActive: false,
    priority: 0,
    startsAt: DateTime.utc(2026, 1, 1),
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
    translations: const [
      AdminCampaignTranslation(locale: 'tr', title: 'Eski', description: ''),
    ],
    displayMode: displayMode,
  );
}

Widget _app({
  required Widget child,
  Locale locale = const Locale('tr'),
}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: const [Locale('tr'), Locale('en')],
    localeResolutionCallback: (proposed, supported) => locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: ThemeData.dark(),
    home: Scaffold(body: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(configureContentWidgetTests);

  Future<void> pumpForm(
    WidgetTester tester, {
    required _FakeCampaigns repo,
    AdminCampaign? existing,
    Locale locale = const Locale('tr'),
    CampaignImageController? imageController,
    Future<({Uint8List bytes, String fileName})?> Function()? filePicker,
    Future<PopupImagePixelSize?> Function(Uint8List bytes)? imageSizeDecoder,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1200, 2800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _app(
        locale: locale,
        child: PopupCampaignFormDialog(
          repository: repo,
          existing: existing,
          userRepository: _FakeUsers(),
          imageController: imageController,
          filePicker: filePicker,
          imageSizeDecoder: imageSizeDecoder,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  test('new campaign default display mode is once', () {
    expect(CampaignDisplayMode.defaultValue, 'once');
    expect(CampaignDisplayMode.normalize(null), 'once');
    expect(
      AdminCampaign.fromMap({
        'id': 'x',
        'image_path': '',
        'destination_type': 'none',
        'target_locales': ['tr'],
        'is_active': false,
        'priority': 0,
        'starts_at': '2026-01-01T00:00:00Z',
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
        'translations': [],
      }).displayMode,
      'once',
    );
  });

  testWidgets('new form defaults to once', (tester) async {
    final repo = _FakeCampaigns();
    await pumpForm(tester, repo: repo);
    final button = tester.widget<SegmentedButton<String>>(
      find.byKey(const Key('campaign-display-mode')),
    );
    expect(button.selected, {CampaignDisplayMode.once});

    await tester.ensureVisible(find.text('Oluştur'));
    await tester.tap(find.text('Oluştur'));
    await tester.pumpAndSettle();
    expect(repo.upsertCalls, 1);
    expect(repo.lastDisplayMode, 'once');
    expect(repo.lastTranslations.single.title, 'Popup');
  });

  testWidgets('edit existing campaign loads once', (tester) async {
    final repo = _FakeCampaigns();
    await pumpForm(tester, repo: repo, existing: _existing());
    final button = tester.widget<SegmentedButton<String>>(
      find.byKey(const Key('campaign-display-mode')),
    );
    expect(button.selected, {CampaignDisplayMode.once});
  });

  testWidgets('recurring selection serializes correct value', (tester) async {
    final repo = _FakeCampaigns();
    await pumpForm(tester, repo: repo);
    await tapVisible(tester, find.text('Tekrarlanabilir'));
    await tapVisible(tester, find.text('Oluştur'));
    expect(repo.lastDisplayMode, 'recurring');
  });

  testWidgets('switching recurring to once works', (tester) async {
    final repo = _FakeCampaigns();
    await pumpForm(
      tester,
      repo: repo,
      existing: _existing(displayMode: 'recurring'),
    );
    expect(
      tester
          .widget<SegmentedButton<String>>(
            find.byKey(const Key('campaign-display-mode')),
          )
          .selected,
      {CampaignDisplayMode.recurring},
    );
    await tapVisible(tester, find.text('Bir kez'));
    await tapVisible(tester, find.text('Güncelle'));
    expect(repo.lastDisplayMode, 'once');
  });

  testWidgets('TR display-mode labels and helper', (tester) async {
    await pumpForm(tester, repo: _FakeCampaigns());
    expect(find.text('Gösterim'), findsOneWidget);
    expect(find.text('Bir kez'), findsOneWidget);
    expect(find.text('Tekrarlanabilir'), findsOneWidget);
    expect(
      find.text(
        'Tekrarlanabilir kampanyalar dönüşümlü gösterilir. Bir pop-up gösterildikten sonraki uygulama açılışında hiçbir tanıtım pop-up’ı gösterilmez.',
      ),
      findsNothing,
    );
    expect(
      find.byKey(const Key('campaign-display-mode-helper')),
      findsOneWidget,
    );
    expect(
      find.textContaining('tanıtım pop-up'),
      findsOneWidget,
    );
  });

  testWidgets('EN display-mode labels and helper', (tester) async {
    await pumpForm(
      tester,
      repo: _FakeCampaigns(),
      locale: const Locale('en'),
    );
    expect(find.text('Display'), findsWidgets);
    expect(find.text('Once'), findsOneWidget);
    expect(find.text('Recurring'), findsOneWidget);
    expect(
      find.textContaining('no promotional popup is shown on the next app launch'),
      findsOneWidget,
    );
  });

  testWidgets('test-only and recurring coexist', (tester) async {
    final repo = _FakeCampaigns();
    await pumpForm(tester, repo: repo);
    await tapVisible(tester, find.byKey(const Key('campaign-test-only-toggle')));
    await tester.enterText(
      find.byKey(const Key('campaign-test-user-search')),
      'qa@vidxon.test',
    );
    await tester.tap(find.byKey(const Key('campaign-test-user-search-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('QA User'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Tekrarlanabilir'));
    await tapVisible(tester, find.text('Oluştur'));
    expect(repo.lastTestOnly, isTrue);
    expect(repo.lastTestUserId, _testUserId);
    expect(repo.lastDisplayMode, 'recurring');
    expect(repo.lastDestinationType, 'none');
  });

  testWidgets('recommended 1080x1350 and transparency guidance are visible', (
    tester,
  ) async {
    await pumpForm(tester, repo: _FakeCampaigns());
    expect(find.byKey(const Key('campaign-image-guidance')), findsOneWidget);
    expect(find.textContaining('1080 × 1350'), findsOneWidget);
    expect(find.textContaining('4:5'), findsOneWidget);
    expect(find.textContaining('PNG'), findsWidgets);
    expect(find.textContaining('WebP'), findsWidgets);
    expect(find.textContaining('10 MB'), findsOneWidget);
    expect(find.textContaining('şeffaf'), findsOneWidget);
  });

  testWidgets('EN image guidance is localized', (tester) async {
    await pumpForm(
      tester,
      repo: _FakeCampaigns(),
      locale: const Locale('en'),
    );
    expect(find.textContaining('1080 × 1350'), findsOneWidget);
    expect(find.textContaining('transparent background'), findsOneWidget);
    expect(find.textContaining('Maximum: 10 MB'), findsOneWidget);
  });

  testWidgets('selected local image dimensions are shown when known', (
    tester,
  ) async {
    final images = FakeImageUploadRepository();
    final controller = CampaignImageController(imageUploadRepository: images);
    await pumpForm(
      tester,
      repo: _FakeCampaigns(),
      imageController: controller,
      filePicker: () async => (bytes: kTinyPng, fileName: 'promo.png'),
      imageSizeDecoder: (_) async =>
          const PopupImagePixelSize(width: 1200, height: 1500),
    );
    await tapVisible(tester, find.text('Görsel Yükle'));
    expect(find.byKey(const Key('campaign-selected-image-size')), findsOneWidget);
    expect(find.text('Seçilen görsel: 1200 × 1500 px'), findsOneWidget);
    expect(images.lastPurpose, 'campaign_image');
  });

  testWidgets('image dimension detection failure is non-fatal', (tester) async {
    final images = FakeImageUploadRepository();
    final controller = CampaignImageController(imageUploadRepository: images);
    await pumpForm(
      tester,
      repo: _FakeCampaigns(),
      imageController: controller,
      filePicker: () async => (
        bytes: Uint8List.fromList([1, 2, 3, 4]),
        fileName: 'promo.png',
      ),
      imageSizeDecoder: (_) async => null,
    );
    await tapVisible(tester, find.text('Görsel Yükle'));
    expect(find.byKey(const Key('campaign-selected-image-size')), findsNothing);
    expect(controller.objectPath, isNotNull);
    expect(images.lastPurpose, 'campaign_image');
  });

  testWidgets('existing remote image does not invent dimensions', (
    tester,
  ) async {
    await pumpForm(tester, repo: _FakeCampaigns(), existing: _existing());
    expect(find.byKey(const Key('campaign-selected-image-size')), findsNothing);
  });

  testWidgets('popup preview uses contain rather than cover', (tester) async {
    final controller = CampaignImageController(
      imageUploadRepository: FakeImageUploadRepository(),
    );
    controller.previewBytes = kTinyPng;
    await pumpForm(
      tester,
      repo: _FakeCampaigns(),
      imageController: controller,
    );
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.fit, BoxFit.contain);
  });

  test('decodePopupImagePixelSize swallows garbage without throwing', () async {
    final failed = await decodePopupImagePixelSize(
      Uint8List.fromList([1, 2, 3, 4]),
    );
    expect(failed, isNull);
  });
}
