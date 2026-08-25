class UpdateSeriesInput {
  const UpdateSeriesInput({
    required this.seriesId,
    required this.title,
    required this.synopsis,
    required this.status,
    required this.isFeatured,
    required this.isPremium,
    required this.categoryIds,
    required this.expectedContentVersion,
    this.backdropPath,
    this.releaseDate,
    this.contentAgeRating,
    this.contentDescriptors = const [],
  });

  final String seriesId;
  final String title;
  final String synopsis;
  final String status;
  final bool isFeatured;
  final bool isPremium;
  final List<String> categoryIds;
  final int expectedContentVersion;
  final String? backdropPath;
  final String? releaseDate;
  final int? contentAgeRating;
  final List<String> contentDescriptors;

  void validate() {
    if (seriesId.trim().isEmpty) {
      throw FormatException('Series id is required.');
    }

    if (title.trim().isEmpty) {
      throw FormatException('Title is required.');
    }

    if (expectedContentVersion < 0) {
      throw FormatException('Expected content version is invalid.');
    }
  }
}

Map<String, dynamic> buildUpdateSeriesRpcParams(UpdateSeriesInput input) {
  input.validate();

  final synopsis = input.synopsis.trim();
  final backdrop = input.backdropPath?.trim();
  final releaseDate = input.releaseDate?.trim();

  return {
    'p_series_id': input.seriesId.trim(),
    'p_title': input.title.trim(),
    'p_synopsis': synopsis,
    'p_status': input.status,
    'p_is_featured': input.isFeatured,
    'p_is_premium': input.isPremium,
    'p_release_date': releaseDate == null || releaseDate.isEmpty
        ? null
        : releaseDate,
    'p_backdrop_path': backdrop == null || backdrop.isEmpty ? null : backdrop,
    'p_category_ids': input.categoryIds,
    'p_expected_content_version': input.expectedContentVersion,
    'p_content_age_rating': input.contentAgeRating,
    'p_content_descriptors': input.contentDescriptors,
    'p_update_content_rating': true,
  };
}

Map<String, dynamic> buildReplaceSeriesPosterRpcParams({
  required String seriesId,
  required String posterPath,
  required int expectedContentVersion,
}) {
  return {
    'p_series_id': seriesId.trim(),
    'p_new_poster_path': posterPath.trim(),
    'p_expected_content_version': expectedContentVersion,
  };
}

Map<String, dynamic> buildSeriesLifecycleRpcParams({
  required String seriesId,
  required int expectedContentVersion,
}) {
  return {
    'p_series_id': seriesId.trim(),
    'p_expected_content_version': expectedContentVersion,
  };
}

Map<String, dynamic> buildReorderSeriesEpisodesRpcParams({
  required String seriesId,
  required List<String> orderedEpisodeIds,
  required int expectedSeriesVersion,
}) {
  return {
    'p_series_id': seriesId.trim(),
    'p_ordered_episode_ids': orderedEpisodeIds,
    'p_expected_series_version': expectedSeriesVersion,
  };
}
