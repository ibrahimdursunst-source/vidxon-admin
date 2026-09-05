/// Campaign destination types stored by promotional/push campaign RPCs.
///
/// Backend CHECK allows exactly these five values. There is no Home or URL
/// destination in the campaign schema.
abstract final class CampaignDestinationType {
  static const none = 'none';
  static const series = 'series';
  static const episode = 'episode';
  static const coinPurchase = 'coin_purchase';
  static const membership = 'membership';

  static const all = <String>[
    none,
    series,
    episode,
    coinPurchase,
    membership,
  ];

  static bool needsSeriesPicker(String type) =>
      type == series || type == episode;

  static bool needsEpisodePicker(String type) => type == episode;

  static bool needsEntityId(String type) =>
      type == series || type == episode;
}

class CampaignDestinationOption {
  const CampaignDestinationOption(this.value, this.label);

  final String value;
  final String label;
}

const List<CampaignDestinationOption> kCampaignDestinationOptions = [
  CampaignDestinationOption(CampaignDestinationType.none, 'Bilgilendirme'),
  CampaignDestinationOption(CampaignDestinationType.series, 'Dizi'),
  CampaignDestinationOption(CampaignDestinationType.episode, 'Bölüm'),
  CampaignDestinationOption(
    CampaignDestinationType.coinPurchase,
    'Jeton Satın Al',
  ),
  CampaignDestinationOption(CampaignDestinationType.membership, 'Üyelik'),
];

/// Popup-only priority semantics from `get_eligible_campaign_v1`:
/// `ORDER BY priority DESC, starts_at DESC, id LIMIT 1`.
/// Default column/RPC value is 0. No CHECK min/max. Push has no priority.
abstract final class CampaignPriority {
  static const defaultValue = 0;
  static const label = 'Öncelik';
  static const helperText =
      'Aynı anda birden fazla uygun kampanya varsa, daha yüksek öncelikli kampanya önce gösterilir. Eşit öncelikte daha yeni başlangıç tarihi kazanır. Varsayılan: 0.';

  static int parseOrDefault(String? raw) {
    final trimmed = raw?.trim() ?? '';
    if (trimmed.isEmpty) return defaultValue;
    return int.tryParse(trimmed) ?? defaultValue;
  }
}

String campaignSeriesPickerLabel(String title, {required bool isPublished}) {
  final status = isPublished ? 'Yayında' : 'Yayında Değil';
  return '$title · $status';
}

String campaignEpisodePickerLabel({
  required int episodeNumber,
  required String title,
}) {
  final trimmed = title.trim();
  if (trimmed.isEmpty) {
    return 'Bölüm $episodeNumber';
  }
  return 'Bölüm $episodeNumber · $trimmed';
}
