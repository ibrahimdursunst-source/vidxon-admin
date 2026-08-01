import 'package:supabase_flutter/supabase_flutter.dart';

import '../../content/data/content_errors.dart';
import '../domain/stream_preview_response.dart';

class EpisodePreviewRepository {
  EpisodePreviewRepository({this._client});

  final SupabaseClient? _client;

  SupabaseClient get _resolvedClient => _client ?? Supabase.instance.client;

  Future<StreamPreviewResponse> createPreviewUrl({
    required String episodeId,
    required String videoSource,
  }) async {
    try {
      final response = await _resolvedClient.functions.invoke(
        'admin-create-stream-preview-url',
        body: buildStreamPreviewRequest(
          episodeId: episodeId,
          videoSource: videoSource,
        ),
      );

      if (response.status != 200) {
        throw ContentErrorMapper.fromFunctionResponse(
          status: response.status,
          data: response.data,
        );
      }

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const ContentException(
          message: 'Önizleme yanıtı geçersiz.',
          kind: ContentFailureKind.serverError,
        );
      }

      return StreamPreviewResponse.fromJson(data);
    } on FunctionException catch (error) {
      throw ContentErrorMapper.fromFunctionResponse(
        status: error.status,
        data: error.details,
      );
    } on ContentException {
      rethrow;
    } on FormatException {
      throw const ContentException(
        message: 'Önizleme yanıtı geçersiz.',
        kind: ContentFailureKind.serverError,
      );
    } catch (_) {
      throw const ContentException(
        message: 'Önizleme bağlantısı oluşturulamadı.',
        kind: ContentFailureKind.unknown,
      );
    }
  }
}
