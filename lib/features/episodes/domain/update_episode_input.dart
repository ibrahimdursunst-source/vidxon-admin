import 'create_episode_input.dart';
import 'episode_release_at.dart';

const episodeMaxCoinPrice = 10000;

class UpdateEpisodeInput {
  const UpdateEpisodeInput({
    required this.episodeId,
    required this.title,
    required this.synopsis,
    required this.isFree,
    required this.coinPrice,
    required this.expectedContentVersion,
    this.releaseAtLocal,
  });

  final String episodeId;
  final String title;
  final String synopsis;
  final bool isFree;
  final int coinPrice;
  final int expectedContentVersion;
  final DateTime? releaseAtLocal;

  int get normalizedCoinPrice =>
      normalizeCoinPrice(isFree: isFree, coinPrice: coinPrice);

  void validate() {
    if (episodeId.trim().isEmpty) {
      throw EpisodeValidationException('Bölüm bilgisi eksik.');
    }

    if (title.trim().isEmpty) {
      throw EpisodeValidationException('Başlık zorunludur.');
    }

    if (coinPrice < 0) {
      throw EpisodeValidationException('Coin fiyatı negatif olamaz.');
    }

    if (coinPrice > episodeMaxCoinPrice) {
      throw EpisodeValidationException(
        'Coin fiyatı en fazla $episodeMaxCoinPrice olabilir.',
      );
    }

    if (isFree && coinPrice != 0) {
      throw EpisodeValidationException(
        'Ücretsiz bölümlerde coin fiyatı 0 olmalıdır.',
      );
    }

    if (expectedContentVersion < 0) {
      throw EpisodeValidationException('İçerik sürüm bilgisi geçersiz.');
    }
  }
}

Map<String, dynamic> buildUpdateEpisodeRpcParams(UpdateEpisodeInput input) {
  input.validate();

  return {
    'p_episode_id': input.episodeId.trim(),
    'p_title': input.title.trim(),
    'p_synopsis': input.synopsis.trim(),
    'p_is_free': input.isFree,
    'p_coin_price': input.normalizedCoinPrice,
    'p_release_at': releaseAtLocalToRpcPayload(input.releaseAtLocal),
    'p_expected_content_version': input.expectedContentVersion,
  };
}

Map<String, dynamic> buildEpisodeLifecycleRpcParams({
  required String episodeId,
  required int expectedContentVersion,
}) {
  return {
    'p_episode_id': episodeId.trim(),
    'p_expected_content_version': expectedContentVersion,
  };
}

Map<String, dynamic> buildRequestStreamReplacementRpcParams({
  required String episodeId,
  required String streamUid,
  required int expectedContentVersion,
}) {
  return {
    'p_episode_id': episodeId.trim(),
    'p_stream_uid': streamUid.trim(),
    'p_expected_content_version': expectedContentVersion,
  };
}
