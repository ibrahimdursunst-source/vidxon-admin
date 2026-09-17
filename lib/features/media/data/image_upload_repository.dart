import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/image_upload_response.dart';

class ImageUploadException implements Exception {
  ImageUploadException(this.message);

  final String message;

  @override
  String toString() => message;
}

const imageUploadUrlFailedMessage =
    'Yükleme bağlantısı oluşturulamadı. Lütfen tekrar deneyin.';
const imageUploadPutFailedMessage =
    'Poster yüklenemedi. Lütfen tekrar deneyin.';
const imageUploadSessionExpiredMessage =
    'Oturum süresi doldu. Lütfen tekrar giriş yapın.';

String imageUploadUrlFailureMessage({int? status}) {
  if (status == 401) {
    return imageUploadSessionExpiredMessage;
  }
  return imageUploadUrlFailedMessage;
}

class ImageUploadRepository {
  ImageUploadRepository({this._client, http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final SupabaseClient? _client;
  final http.Client _httpClient;

  SupabaseClient get _resolvedClient => _client ?? Supabase.instance.client;

  Future<ImageUploadResponse> requestPosterUploadUrl({
    required String contentType,
    required int fileSize,
    String purpose = 'series_create',
    String? seriesId,
  }) async {
    final body = <String, dynamic>{
      'kind': 'poster',
      'contentType': contentType,
      'fileSize': fileSize,
      'purpose': purpose,
    };

    if (seriesId != null && seriesId.trim().isNotEmpty) {
      body['seriesId'] = seriesId.trim();
    }

    try {
      final response = await _resolvedClient.functions.invoke(
        'admin-create-image-upload-url',
        body: body,
      );

      if (response.status != 200) {
        throw ImageUploadException(
          imageUploadUrlFailureMessage(status: response.status),
        );
      }

      final data = response.data;
      if (data is! Map) {
        throw ImageUploadException('Yükleme bağlantısı yanıtı geçersiz.');
      }

      return ImageUploadResponse.fromJson(Map<String, dynamic>.from(data));
    } on ImageUploadException {
      rethrow;
    } on FunctionException catch (error) {
      throw ImageUploadException(
        imageUploadUrlFailureMessage(status: error.status),
      );
    } on FormatException {
      throw ImageUploadException('Yükleme bağlantısı yanıtı geçersiz.');
    } catch (_) {
      throw ImageUploadException(imageUploadUrlFailedMessage);
    }
  }

  Future<void> uploadPoster({
    required ImageUploadResponse uploadInfo,
    required Uint8List fileBytes,
  }) async {
    try {
      final headers = Map<String, String>.from(uploadInfo.requiredHeaders);

      final response = await _httpClient.put(
        Uri.parse(uploadInfo.uploadUrl),
        headers: headers,
        body: fileBytes,
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        return;
      }

      throw ImageUploadException(imageUploadPutFailedMessage);
    } on ImageUploadException {
      rethrow;
    } catch (_) {
      throw ImageUploadException(imageUploadPutFailedMessage);
    }
  }
}
