/// Popup campaign display modes persisted by admin_upsert_campaign_v1.
abstract final class CampaignDisplayMode {
  static const once = 'once';
  static const recurring = 'recurring';
  static const defaultValue = once;

  static const all = <String>[once, recurring];

  static bool isValid(String? value) =>
      value == once || value == recurring;

  static String normalize(String? value) {
    return isValid(value) ? value! : defaultValue;
  }
}
