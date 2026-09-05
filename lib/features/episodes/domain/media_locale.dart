import '../../../core/locale/vidxon_product_locales.dart';

/// Vidxon product locale helpers. `pt` and `pt_BR` are distinct — never fuzzy-match.
abstract final class MediaLocale {
  /// Accepts `tr`, `pt_BR` (region), or `zh_Hans` (ISO 15924 script).
  static final RegExp pattern = RegExp(
    r'^[a-z]{2,3}(_([A-Z]{2}|[A-Z][a-z]{3}))?$',
  );

  /// Curated Vidxon UI suggestions; arbitrary valid locales are still allowed.
  static const List<String> suggestedLocales = VidxonProductLocales.all;

  static bool isValid(String? value) {
    if (value == null) {
      return false;
    }
    return pattern.hasMatch(value);
  }

  static String? normalizeOrNull(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    if (!isValid(trimmed)) {
      return null;
    }
    return trimmed;
  }

  static String toBcp47(String vidxonLocale) =>
      vidxonLocale.replaceAll('_', '-');

  static String displayName(String locale) =>
      VidxonProductLocales.displayName(locale);
}
