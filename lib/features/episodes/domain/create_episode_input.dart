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
    required this.isPublished,
    this.synopsis = '',
    this.releaseAtLocal,
  });

  final String seriesId;
  final int episodeNumber;
  final String title;
  final String synopsis;
  final bool isFree;
  final int coinPrice;
  final bool isPublished;
  final DateTime? releaseAtLocal;

  int get normalizedCoinPrice =>
      normalizeCoinPrice(isFree: isFree, coinPrice: coinPrice);

  void validate() {
    final error = validateEpisodeFields(
      episodeNumber: episodeNumber,
      title: title,
      isFree: isFree,
      coinPrice: normalizedCoinPrice,
      isPublished: isPublished,
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
    'p_is_published': input.isPublished,
    'p_release_at': releaseAtLocalToRpcPayload(input.releaseAtLocal),
  };
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
  required bool isPublished,
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

  if (isFree && coinPrice != 0) {
    return 'Ücretsiz bölümlerde coin fiyatı 0 olmalıdır.';
  }

  if (isPublished && !isFree && coinPrice <= 0) {
    return 'Yayında kilitli bölümlerde coin fiyatı 0\'dan büyük olmalıdır.';
  }

  return null;
}
