import 'create_episode_input.dart';
import 'episode_release_at.dart';

class UpdateEpisodeInput {
  const UpdateEpisodeInput({
    required this.episodeId,
    required this.episodeNumber,
    required this.title,
    required this.isFree,
    required this.coinPrice,
    required this.isPublished,
    this.synopsis = '',
    this.releaseAtLocal,
  });

  final String episodeId;
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

    if (episodeId.trim().isEmpty) {
      throw EpisodeValidationException('Bölüm bilgisi eksik.');
    }
  }
}

Map<String, dynamic> buildUpdateEpisodeRpcParams(UpdateEpisodeInput input) {
  input.validate();

  return {
    'p_episode_id': input.episodeId.trim(),
    'p_episode_number': input.episodeNumber,
    'p_title': input.title.trim(),
    'p_synopsis': input.synopsis.trim(),
    'p_is_free': input.isFree,
    'p_coin_price': input.normalizedCoinPrice,
    'p_is_published': input.isPublished,
    'p_release_at': releaseAtLocalToRpcPayload(input.releaseAtLocal),
  };
}
