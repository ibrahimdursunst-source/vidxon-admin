/// Vidxon product locale helpers. `pt` and `pt_BR` are distinct — never fuzzy-match.
abstract final class MediaLocale {
  static final RegExp pattern = RegExp(r'^[a-z]{2,3}(_[A-Z]{2})?$');

  /// Common suggestions; arbitrary valid locales are still allowed.
  static const List<String> suggestedLocales = [
    'tr',
    'en',
    'es',
    'pt',
    'pt_BR',
    'ar',
    'id',
  ];

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
}
