class CreateSeriesInput {
  const CreateSeriesInput({
    required this.title,
    required this.slug,
    required this.posterPath,
    required this.status,
    required this.isFeatured,
    required this.isPremium,
    required this.categoryIds,
    this.synopsis,
    this.releaseDate,
    this.contentAgeRating,
    this.contentDescriptors = const [],
  });

  final String title;
  final String slug;
  final String posterPath;
  final String? synopsis;
  final String status;
  final bool isFeatured;
  final bool isPremium;
  final String? releaseDate;
  final List<String> categoryIds;
  final int? contentAgeRating;
  final List<String> contentDescriptors;
}

Map<String, dynamic> buildCreateSeriesRpcParams(CreateSeriesInput input) {
  final synopsis = input.synopsis?.trim();
  final releaseDate = input.releaseDate?.trim();

  return {
    'p_title': input.title.trim(),
    'p_slug': input.slug.trim(),
    'p_poster_path': input.posterPath.trim(),
    'p_synopsis': synopsis == null || synopsis.isEmpty ? null : synopsis,
    'p_backdrop_path': null,
    'p_status': input.status,
    'p_is_published': false,
    'p_is_featured': input.isFeatured,
    'p_is_premium': input.isPremium,
    'p_release_date': releaseDate == null || releaseDate.isEmpty
        ? null
        : releaseDate,
    'p_category_ids': input.categoryIds,
    'p_content_age_rating': input.contentAgeRating,
    'p_content_descriptors': input.contentDescriptors,
  };
}
