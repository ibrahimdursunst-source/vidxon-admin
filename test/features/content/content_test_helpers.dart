import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:vidxon_admin/features/categories/data/category_repository.dart';
import 'package:vidxon_admin/features/categories/domain/admin_category.dart';
import 'package:vidxon_admin/features/content/data/content_errors.dart';
import 'package:vidxon_admin/features/episodes/data/episode_preview_repository.dart';
import 'package:vidxon_admin/features/episodes/data/episode_repository.dart';
import 'package:vidxon_admin/features/episodes/domain/admin_episode.dart';
import 'package:vidxon_admin/features/episodes/domain/cloudflare_stream_status.dart';
import 'package:vidxon_admin/features/episodes/domain/reorder_snapshot.dart';
import 'package:vidxon_admin/features/episodes/domain/stream_preview_response.dart';
import 'package:vidxon_admin/features/media/data/image_upload_repository.dart';
import 'package:vidxon_admin/features/media/domain/image_upload_response.dart';
import 'package:vidxon_admin/features/media/domain/poster_file.dart';
import 'package:vidxon_admin/features/series/data/series_mutation_repository.dart';
import 'package:vidxon_admin/features/series/data/series_repository.dart';
import 'package:vidxon_admin/features/series/domain/admin_series.dart';
import 'package:vidxon_admin/features/series/domain/create_series_input.dart';
import 'package:vidxon_admin/features/dashboard/data/dashboard_repository.dart';
import 'package:vidxon_admin/features/dashboard/domain/dashboard_counts.dart';
import 'package:vidxon_admin/features/series/domain/series_mutation_results.dart';

const testSeriesId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
const testEpisodeId1 = '11111111-1111-1111-1111-111111111111';
const testEpisodeId2 = '22222222-2222-2222-2222-222222222222';

PosterFile testPosterFile() {
  return PosterFile(
    bytes: Uint8List.fromList([1, 2, 3, 4]),
    fileName: 'poster.png',
    extension: 'png',
    contentType: 'image/png',
  );
}

class FakeDashboardRepository extends DashboardRepository {
  FakeDashboardRepository() : super(client: null);

  @override
  Future<DashboardCounts> fetchCounts() async {
    return const DashboardCounts(
      categoryCount: 1,
      seriesCount: 1,
      episodeCount: 2,
    );
  }
}

ImageUploadResponse testImageUploadResponse() {
  return ImageUploadResponse(
    uploadUrl: 'https://upload.example.com/poster',
    objectPath: 'posters/test/poster.png',
    publicUrl: 'https://media.example.com/posters/test/poster.png',
    contentType: 'image/png',
    requiredHeaders: const {'Content-Type': 'image/png'},
    expiresIn: 3600,
  );
}

AdminSeries testSeries({
  String id = testSeriesId,
  String title = 'Test Dizi',
  String slug = 'test-dizi',
  bool isPublished = false,
  bool isArchived = false,
  int contentVersion = 0,
  String posterPath = '',
}) {
  return AdminSeries(
    id: id,
    title: title,
    slug: slug,
    synopsis: 'Synopsis',
    posterPath: posterPath,
    status: 'ongoing',
    isPublished: isPublished,
    isArchived: isArchived,
    contentVersion: contentVersion,
    totalViews: 0,
    categories: const ['Drama'],
    categoryIds: const ['cccccccc-cccc-cccc-cccc-cccccccccccc'],
    episodeCount: 2,
    updatedAt: DateTime.utc(2026, 8, 1),
  );
}

AdminEpisode testEpisode({
  String id = testEpisodeId1,
  int episodeNumber = 1,
  String title = 'Bölüm 1',
  bool isPublished = false,
  bool isArchived = false,
  bool isFree = true,
  int coinPrice = 0,
  int contentVersion = 0,
  CloudflareStreamStatus streamStatus = CloudflareStreamStatus.none,
  CloudflareStreamStatus pendingStatus = CloudflareStreamStatus.none,
}) {
  return AdminEpisode.fromMap({
    'id': id,
    'series_id': testSeriesId,
    'episode_number': episodeNumber,
    'title': title,
    'synopsis': '',
    'cloudflare_stream_status': streamStatus.name,
    'cloudflare_stream_pending_status': pendingStatus.name,
    'is_free': isFree,
    'coin_price': coinPrice,
    'is_published': isPublished,
    'is_archived': isArchived,
    'content_version': contentVersion,
    'total_views': 0,
  });
}

class FakeCategoryRepository extends CategoryRepository {
  FakeCategoryRepository([this.categories = const []]) : super(client: null);

  final List<AdminCategory> categories;

  @override
  Future<List<AdminCategory>> fetchAll() async => categories;
}

class FakeImageUploadRepository extends ImageUploadRepository {
  FakeImageUploadRepository() : super(client: null);

  int requestCount = 0;
  int uploadCount = 0;

  @override
  Future<ImageUploadResponse> requestPosterUploadUrl({
    required String contentType,
    required int fileSize,
    String purpose = 'series_create',
    String? seriesId,
  }) async {
    requestCount += 1;
    return testImageUploadResponse();
  }

  @override
  Future<void> uploadPoster({
    required ImageUploadResponse uploadInfo,
    required Uint8List fileBytes,
  }) async {
    uploadCount += 1;
  }
}

class FakeSeriesRepository extends SeriesRepository {
  FakeSeriesRepository(this._fetchById, {this.fetchAllResult = const []})
    : super(client: null);

  final Future<AdminSeries> Function(String seriesId) _fetchById;
  final List<AdminSeries> fetchAllResult;
  int fetchAllCalls = 0;
  int fetchByIdCalls = 0;

  @override
  Future<List<AdminSeries>> fetchAll() async {
    fetchAllCalls += 1;
    return fetchAllResult;
  }

  @override
  Future<AdminSeries> fetchById(String seriesId) async {
    fetchByIdCalls += 1;
    return _fetchById(seriesId);
  }
}

class FakeSeriesMutationRepository extends SeriesMutationRepository {
  FakeSeriesMutationRepository() : super(client: null);

  CreateSeriesInput? lastCreateInput;
  int createCalls = 0;
  int publishCalls = 0;
  int unpublishCalls = 0;
  int archiveCalls = 0;
  int restoreCalls = 0;
  int replacePosterCalls = 0;
  int reorderCalls = 0;

  int? lastPublishExpectedVersion;
  int? lastReplaceExpectedVersion;
  int? lastReorderExpectedVersion;
  List<String>? lastReorderEpisodeIds;

  SeriesPosterReplaceResult? replacePosterResult;
  Object? publishError;
  Object? unpublishError;
  Object? archiveError;
  Object? restoreError;
  Object? replacePosterError;
  Completer<void>? unpublishDelay;

  AdminSeries? createResult;
  SeriesLifecycleResult Function({
    required String seriesId,
    required int expectedContentVersion,
  })?
  publishHandler;

  @override
  Future<AdminSeries> createSeries(CreateSeriesInput input) async {
    createCalls += 1;
    lastCreateInput = input;
    if (createResult == null) {
      throw const ContentException(
        message: 'Create failed',
        kind: ContentFailureKind.serverError,
      );
    }
    return createResult!;
  }

  @override
  Future<SeriesLifecycleResult> publishSeries({
    required String seriesId,
    required int expectedContentVersion,
  }) async {
    publishCalls += 1;
    lastPublishExpectedVersion = expectedContentVersion;
    if (publishError != null) {
      throw publishError!;
    }
    if (publishHandler != null) {
      return publishHandler!(
        seriesId: seriesId,
        expectedContentVersion: expectedContentVersion,
      );
    }
    return SeriesLifecycleResult(
      seriesId: seriesId,
      isPublished: true,
      isArchived: false,
      contentVersion: expectedContentVersion + 1,
      updatedAt: DateTime.utc(2026, 8, 1, 12),
    );
  }

  @override
  Future<SeriesLifecycleResult> unpublishSeries({
    required String seriesId,
    required int expectedContentVersion,
  }) async {
    unpublishCalls += 1;
    if (unpublishDelay != null) {
      await unpublishDelay!.future;
    }
    if (unpublishError != null) {
      throw unpublishError!;
    }
    return SeriesLifecycleResult(
      seriesId: seriesId,
      isPublished: false,
      isArchived: false,
      contentVersion: expectedContentVersion + 1,
      updatedAt: DateTime.utc(2026, 8, 1, 12),
    );
  }

  @override
  Future<SeriesLifecycleResult> archiveSeries({
    required String seriesId,
    required int expectedContentVersion,
  }) async {
    archiveCalls += 1;
    if (archiveError != null) {
      throw archiveError!;
    }
    return SeriesLifecycleResult(
      seriesId: seriesId,
      isPublished: false,
      isArchived: true,
      contentVersion: expectedContentVersion + 1,
      updatedAt: DateTime.utc(2026, 8, 1, 12),
    );
  }

  @override
  Future<SeriesLifecycleResult> restoreSeries({
    required String seriesId,
    required int expectedContentVersion,
  }) async {
    restoreCalls += 1;
    if (restoreError != null) {
      throw restoreError!;
    }
    return SeriesLifecycleResult(
      seriesId: seriesId,
      isPublished: false,
      isArchived: false,
      contentVersion: expectedContentVersion + 1,
      updatedAt: DateTime.utc(2026, 8, 1, 12),
    );
  }

  @override
  Future<SeriesPosterReplaceResult> replacePoster({
    required String seriesId,
    required String posterPath,
    required int expectedContentVersion,
  }) async {
    replacePosterCalls += 1;
    lastReplaceExpectedVersion = expectedContentVersion;
    if (replacePosterError != null) {
      throw replacePosterError!;
    }
    return replacePosterResult ??
        SeriesPosterReplaceResult(
          seriesId: seriesId,
          posterPath: posterPath,
          contentVersion: expectedContentVersion + 1,
          updatedAt: DateTime.utc(2026, 8, 1, 12),
        );
  }

  @override
  Future<SeriesReorderResult> reorderEpisodes({
    required String seriesId,
    required List<String> orderedEpisodeIds,
    required int expectedSeriesVersion,
  }) async {
    reorderCalls += 1;
    lastReorderEpisodeIds = List<String>.from(orderedEpisodeIds);
    lastReorderExpectedVersion = expectedSeriesVersion;
    return SeriesReorderResult(
      seriesId: seriesId,
      contentVersion: expectedSeriesVersion + 1,
      updatedAt: DateTime.utc(2026, 8, 1, 12),
    );
  }
}

class FakeEpisodeRepository extends EpisodeRepository {
  FakeEpisodeRepository(
    this._episodes, {
    this.reorderSnapshot,
    this.reorderSnapshotError,
    this.reorderSnapshotContentVersion = 0,
  }) : super(client: null);

  List<AdminEpisode> _episodes;
  final ReorderSnapshot? reorderSnapshot;
  final Object? reorderSnapshotError;
  int reorderSnapshotContentVersion;
  int fetchListCalls = 0;
  int fetchByIdCalls = 0;
  int loadReorderSnapshotCalls = 0;
  int publishCalls = 0;
  int unpublishCalls = 0;
  int archiveCalls = 0;
  int restoreCalls = 0;
  int? lastPublishExpectedVersion;
  Object? publishError;
  Completer<void>? publishDelay;

  @override
  Future<List<AdminEpisode>> fetchEpisodesForSeries(String seriesId) async {
    fetchListCalls += 1;
    return List<AdminEpisode>.from(_episodes);
  }

  @override
  Future<ReorderSnapshot> loadReorderSnapshot(String seriesId) async {
    loadReorderSnapshotCalls += 1;
    if (reorderSnapshotError != null) {
      throw reorderSnapshotError!;
    }

    if (reorderSnapshot != null) {
      return reorderSnapshot!;
    }

    return ReorderSnapshot(
      seriesId: seriesId,
      activeEpisodes: activeEpisodes(_episodes),
      contentVersion: reorderSnapshotContentVersion,
    );
  }

  void setEpisodes(List<AdminEpisode> episodes) {
    _episodes = episodes;
  }

  @override
  Future<AdminEpisode> fetchById(String episodeId) async {
    fetchByIdCalls += 1;
    return _episodes.firstWhere((episode) => episode.id == episodeId);
  }

  @override
  Future<AdminEpisode> publishEpisode({
    required String episodeId,
    required int expectedContentVersion,
  }) async {
    publishCalls += 1;
    lastPublishExpectedVersion = expectedContentVersion;
    if (publishDelay != null) {
      await publishDelay!.future;
    }
    if (publishError != null) {
      throw publishError!;
    }
    final index = _episodes.indexWhere((episode) => episode.id == episodeId);
    final updated = _episodes[index].copyWith(
      isPublished: true,
      contentVersion: expectedContentVersion + 1,
    );
    _episodes[index] = updated;
    return updated;
  }

  @override
  Future<AdminEpisode> unpublishEpisode({
    required String episodeId,
    required int expectedContentVersion,
  }) async {
    unpublishCalls += 1;
    final index = _episodes.indexWhere((episode) => episode.id == episodeId);
    final updated = _episodes[index].copyWith(
      isPublished: false,
      contentVersion: expectedContentVersion + 1,
    );
    _episodes[index] = updated;
    return updated;
  }

  @override
  Future<AdminEpisode> archiveEpisode({
    required String episodeId,
    required int expectedContentVersion,
  }) async {
    archiveCalls += 1;
    final index = _episodes.indexWhere((episode) => episode.id == episodeId);
    final updated = _episodes[index].copyWith(
      isArchived: true,
      isPublished: false,
      contentVersion: expectedContentVersion + 1,
    );
    _episodes[index] = updated;
    return updated;
  }

  @override
  Future<AdminEpisode> restoreEpisode({
    required String episodeId,
    required int expectedContentVersion,
  }) async {
    restoreCalls += 1;
    final index = _episodes.indexWhere((episode) => episode.id == episodeId);
    final updated = _episodes[index].copyWith(
      isArchived: false,
      isPublished: false,
      contentVersion: expectedContentVersion + 1,
    );
    _episodes[index] = updated;
    return updated;
  }
}

class FakeEpisodePreviewRepository extends EpisodePreviewRepository {
  FakeEpisodePreviewRepository() : super(client: null);

  int callCount = 0;
  String? lastEpisodeId;
  String? lastVideoSource;
  StreamPreviewResponse? response;

  @override
  Future<StreamPreviewResponse> createPreviewUrl({
    required String episodeId,
    required String videoSource,
  }) async {
    callCount += 1;
    lastEpisodeId = episodeId;
    lastVideoSource = videoSource;
    return response ??
        StreamPreviewResponse(
          previewUrl: 'https://preview.example.com/$callCount',
          expiresAt: DateTime.utc(2026, 8, 1, 13),
          episodeId: episodeId,
          videoSource: videoSource,
        );
  }
}

class TrackingSeriesMutationRepository extends FakeSeriesMutationRepository {
  TrackingSeriesMutationRepository({
    this.reorderThrowsConflict = false,
    this.reorderConflictForExpectedVersions,
  });

  final bool reorderThrowsConflict;
  final Set<int>? reorderConflictForExpectedVersions;
  Completer<void>? reorderDelay;

  @override
  Future<SeriesReorderResult> reorderEpisodes({
    required String seriesId,
    required List<String> orderedEpisodeIds,
    required int expectedSeriesVersion,
  }) async {
    reorderCalls += 1;
    lastReorderEpisodeIds = List<String>.from(orderedEpisodeIds);
    lastReorderExpectedVersion = expectedSeriesVersion;

    if (reorderDelay != null) {
      await reorderDelay!.future;
    }

    final shouldConflict =
        reorderThrowsConflict ||
        (reorderConflictForExpectedVersions?.contains(expectedSeriesVersion) ??
            false);
    if (shouldConflict) {
      throw const ContentException(
        message: ContentErrorMapper.conflictMessage,
        kind: ContentFailureKind.conflict,
        isConflict: true,
      );
    }

    return SeriesReorderResult(
      seriesId: seriesId,
      contentVersion: expectedSeriesVersion + 1,
      updatedAt: DateTime.utc(2026, 8, 1, 12),
    );
  }
}

void configureContentWidgetTests() {
  FlutterError.onError = (details) {
    final message = details.exceptionAsString();
    if (details.library == 'image resource service' ||
        message.contains('NetworkImageLoadException') ||
        message.contains('HTTP request failed')) {
      return;
    }
    FlutterError.presentError(details);
  };
  HttpOverrides.global = _EmptyHttpOverrides();
}

class _EmptyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _EmptyHttpClient();
  }
}

class _EmptyHttpClient implements HttpClient {
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    return _EmptyHttpClientRequest();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _EmptyHttpClientRequest implements HttpClientRequest {
  @override
  Future<HttpClientResponse> close() async => _EmptyHttpClientResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _EmptyHttpClientResponse implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  Stream<Uint8List> get body => Stream<Uint8List>.value(Uint8List(0));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
