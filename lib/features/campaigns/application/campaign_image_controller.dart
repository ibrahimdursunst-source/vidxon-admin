import 'dart:typed_data';

import '../../media/data/image_upload_repository.dart';
import '../../media/domain/poster_file.dart';

class CampaignImageController {
  CampaignImageController({
    this.imageUploadRepository,
    String? initialObjectPath,
  }) : objectPath = initialObjectPath;

  final ImageUploadRepository? imageUploadRepository;

  String? objectPath;
  Uint8List? previewBytes;
  bool uploading = false;
  String? errorMessage;

  bool get hasImage => (objectPath != null && objectPath!.trim().isNotEmpty);

  /// Selected local bytes that have not been uploaded yet.
  bool get hasUnsavedSelection => previewBytes != null && !hasImage;

  bool get canSave => !uploading && !hasUnsavedSelection;

  Future<bool> applyPickedBytes({
    required Uint8List bytes,
    required String fileName,
  }) async {
    errorMessage = null;
    try {
      final poster = PosterFileValidator.validate(
        bytes: bytes,
        fileName: fileName,
      );
      previewBytes = poster.bytes;
      uploading = true;
      objectPath = null;

      final repo = imageUploadRepository ?? ImageUploadRepository();
      final uploadInfo = await repo.requestPosterUploadUrl(
        contentType: poster.contentType,
        fileSize: poster.sizeInBytes,
        purpose: 'campaign_image',
      );
      await repo.uploadPoster(uploadInfo: uploadInfo, fileBytes: poster.bytes);
      objectPath = uploadInfo.objectPath;
      uploading = false;
      return true;
    } on PosterFileValidationException catch (e) {
      uploading = false;
      errorMessage = e.message;
      return false;
    } on ImageUploadException catch (e) {
      uploading = false;
      errorMessage = e.message;
      objectPath = null;
      return false;
    } catch (_) {
      uploading = false;
      errorMessage = 'Görsel yüklenemedi.';
      objectPath = null;
      return false;
    }
  }

  void remove() {
    objectPath = null;
    previewBytes = null;
    errorMessage = null;
    uploading = false;
  }
}
