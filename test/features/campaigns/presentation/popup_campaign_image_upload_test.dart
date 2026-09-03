import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/campaigns/application/campaign_image_controller.dart';
import 'package:vidxon_admin/features/campaigns/data/campaign_repository.dart';
import 'package:vidxon_admin/features/campaigns/domain/admin_campaign.dart';
import 'package:vidxon_admin/features/campaigns/presentation/popup_campaign_form_dialog.dart';
import 'package:vidxon_admin/features/media/data/image_upload_repository.dart';

import '../../content/content_test_helpers.dart';

class _FakeCampaignRepository extends CampaignRepository {
  _FakeCampaignRepository() : super(client: null);

  String? lastImagePath;
  int upsertCalls = 0;

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
  }) async {
    upsertCalls += 1;
    lastImagePath = imagePath;
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
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(configureContentWidgetTests);

  test('select/upload success returns canonical campaigns path', () async {
    final images = FakeImageUploadRepository();
    final controller = CampaignImageController(imageUploadRepository: images);
    final ok = await controller.applyPickedBytes(
      bytes: Uint8List.fromList([1, 2, 3, 4]),
      fileName: 'promo.png',
    );
    expect(ok, isTrue);
    expect(images.lastPurpose, 'campaign_image');
    expect(images.uploadCount, 1);
    expect(controller.objectPath, 'campaigns/2026/09/promo.png');
    expect(controller.canSave, isTrue);
  });

  test('upload failure keeps invalid save state', () async {
    final images = FakeImageUploadRepository()
      ..requestError = ImageUploadException('Yükleme bağlantısı oluşturulamadı.');
    final controller = CampaignImageController(imageUploadRepository: images);
    final ok = await controller.applyPickedBytes(
      bytes: Uint8List.fromList([1, 2, 3, 4]),
      fileName: 'promo.png',
    );
    expect(ok, isFalse);
    expect(controller.objectPath, isNull);
    expect(controller.canSave, isFalse);
    expect(controller.errorMessage, isNotNull);
  });

  test('returned path is what save would persist', () async {
    final images = FakeImageUploadRepository();
    final controller = CampaignImageController(imageUploadRepository: images);
    await controller.applyPickedBytes(
      bytes: Uint8List.fromList([1, 2, 3, 4]),
      fileName: 'promo.png',
    );
    final repo = _FakeCampaignRepository();
    expect(controller.canSave, isTrue);
    await repo.upsert(
      imagePath: controller.objectPath?.trim() ?? '',
      startsAt: DateTime.utc(2026, 1, 1),
      translations: const [
        AdminCampaignTranslation(locale: 'tr', title: 'T', description: ''),
      ],
    );
    expect(repo.upsertCalls, 1);
    expect(repo.lastImagePath, 'campaigns/2026/09/promo.png');
  });

  test('cannot save when image required semantics fail upload', () async {
    final images = FakeImageUploadRepository()
      ..requestError = ImageUploadException('fail');
    final controller = CampaignImageController(imageUploadRepository: images);
    await controller.applyPickedBytes(
      bytes: Uint8List.fromList([1, 2, 3, 4]),
      fileName: 'promo.png',
    );
    expect(controller.canSave, isFalse);
  });

  testWidgets('form preview/replace/remove without raw path input', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final images = FakeImageUploadRepository();
    final controller = CampaignImageController(
      initialObjectPath: 'campaigns/old.png',
      imageUploadRepository: images,
    );
    final repo = _FakeCampaignRepository();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: PopupCampaignFormDialog(
            repository: repo,
            imageUploadRepository: images,
            imageController: controller,
            filePicker: () async => (
              bytes: Uint8List.fromList([9, 9, 9, 9]),
              fileName: 'new.png',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Görsel Yolu'), findsNothing);
    expect(find.text('Görsel yüklendi'), findsOneWidget);
    expect(find.text('Görseli Değiştir'), findsOneWidget);

    await tester.tap(find.text('Görseli Değiştir'));
    await tester.pumpAndSettle();
    expect(controller.objectPath, 'campaigns/2026/09/promo.png');
    expect(find.byIcon(Icons.image), findsWidgets);

    await tester.tap(find.text('Görseli Kaldır'));
    await tester.pumpAndSettle();
    expect(controller.hasImage, isFalse);
  });
}
