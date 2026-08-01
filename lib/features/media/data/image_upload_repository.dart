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

    final response = await _resolvedClient.functions.invoke(
      'admin-create-image-upload-url',
      body: body,
    );

    if (response.status != 200) {
      throw ImageUploadException(
        'Yükleme bağlantısı oluşturulamadı. Lütfen tekrar deneyin.',
      );
    }

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw ImageUploadException('Yükleme bağlantısı yanıtı geçersiz.');
    }

    try {
      return ImageUploadResponse.fromJson(data);
    } on FormatException {
      throw ImageUploadException('Yükleme bağlantısı yanıtı geçersiz.');
    }
  }

  Future<void> uploadPoster({
    required ImageUploadResponse uploadInfo,
    required Uint8List fileBytes,
  }) async {
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

    throw ImageUploadException('Poster yüklenemedi. Lütfen tekrar deneyin.');
  }
}
