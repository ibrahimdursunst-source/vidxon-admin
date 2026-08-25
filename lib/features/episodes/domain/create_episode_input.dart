import '../../content_rating/domain/content_rating_catalog.dart';
import 'episode_release_at.dart';

class EpisodeValidationException implements Exception {
  EpisodeValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CreateEpisodeInput {
  const CreateEpisodeInput({
    required this.seriesId,
    required this.episodeNumber,
    required this.title,
    required this.isFree,
    required this.coinPrice,
    this.synopsis = '',
    this.releaseAtLocal,
    this.useContentRatingOverride = false,
    this.contentAgeRating,
    this.contentDescriptors,
  });

  final String seriesId;
  final int episodeNumber;
  final String title;
  final String synopsis;
  final bool isFree;
  final int coinPrice;
  final DateTime? releaseAtLocal;
  final bool useContentRatingOverride;
  final int? contentAgeRating;

  /// When [useContentRatingOverride] is true:
  /// - `null` = inherit series descriptors
  /// - `[]` = explicit empty override
  /// - non-empty = explicit descriptor list
  final List<String>? contentDescriptors;

  int get normalizedCoinPrice =>
      normalizeCoinPrice(isFree: isFree, coinPrice: coinPrice);

  void validate() {
    final error = validateEpisodeFields(
      episodeNumber: episodeNumber,
      title: title,
      isFree: isFree,
      coinPrice: normalizedCoinPrice,
    );

    if (error != null) {
      throw EpisodeValidationException(error);
    }

    if (seriesId.trim().isEmpty) {
      throw EpisodeValidationException('Dizi bilgisi eksik.');
    }
  }
}

Map<String, dynamic> buildCreateEpisodeRpcParams(CreateEpisodeInput input) {
  input.validate();

  return {
    'p_series_id': input.seriesId.trim(),
    'p_episode_number': input.episodeNumber,
    'p_title': input.title.trim(),
    'p_synopsis': input.synopsis.trim(),
    'p_is_free': input.isFree,
    'p_coin_price': input.normalizedCoinPrice,
    'p_is_published': false,
    'p_release_at': releaseAtLocalToRpcPayload(input.releaseAtLocal),
    'p_content_age_rating':
        input.useContentRatingOverride ? input.contentAgeRating : null,
    'p_content_descriptors': input.useContentRatingOverride
        ? normalizeEpisodeContentDescriptors(input.contentDescriptors)
        : null,
  };
}

/// Preserves `null` (inherit) vs `[]` (explicit empty) for episode RPCs.
List<String>? normalizeEpisodeContentDescriptors(List<String>? descriptors) {
  if (descriptors == null) {
    return null;
  }

  return ContentRatingCatalog.normalizeDescriptors(descriptors);
}

int normalizeCoinPrice({required bool isFree, required int coinPrice}) {
  if (isFree) {
    return 0;
  }

  return coinPrice;
}

String? validateEpisodeFields({
  required int episodeNumber,
  required String title,
  required bool isFree,
  required int coinPrice,
}) {
  if (episodeNumber <= 0) {
    return 'Bölüm numarası 0\'dan büyük olmalıdır.';
  }

  if (title.trim().isEmpty) {
    return 'Başlık zorunludur.';
  }

  if (coinPrice < 0) {
    return 'Coin fiyatı negatif olamaz.';
  }

  if (coinPrice > 10000) {
    return 'Coin fiyatı en fazla 10000 olabilir.';
  }

  if (isFree && coinPrice != 0) {
    return 'Ücretsiz bölümlerde coin fiyatı 0 olmalıdır.';
  }

  return null;
}
