class CreateSeriesInput {
  const CreateSeriesInput({
    required this.title,
    required this.slug,
    required this.posterPath,
    required this.status,
    required this.isPublished,
    required this.isFeatured,
    required this.isPremium,
    required this.categoryIds,
    this.synopsis,
    this.releaseDate,
  });

  final String title;
  final String slug;
  final String posterPath;
  final String? synopsis;
  final String status;
  final bool isPublished;
  final bool isFeatured;
  final bool isPremium;
  final String? releaseDate;
  final List<String> categoryIds;
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
    'p_is_published': input.isPublished,
    'p_is_featured': input.isFeatured,
    'p_is_premium': input.isPremium,
    'p_release_date': releaseDate == null || releaseDate.isEmpty
        ? null
        : releaseDate,
    'p_category_ids': input.categoryIds,
  };
}
