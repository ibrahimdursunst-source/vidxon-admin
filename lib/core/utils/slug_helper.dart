class SlugHelper {
  SlugHelper._();

  static final RegExp slugPattern = RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$');

  static String generateFromTitle(String title) {
    final normalized = _normalizeTurkish(title.trim().toLowerCase());
    final slug = normalized
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');

    return slug;
  }

  static bool isValid(String slug) {
    final trimmed = slug.trim();
    return trimmed.isNotEmpty && slugPattern.hasMatch(trimmed);
  }

  static String _normalizeTurkish(String value) {
    return value
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'i')
        .replaceAll('ş', 's')
        .replaceAll('Ş', 's')
        .replaceAll('ğ', 'g')
        .replaceAll('Ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('Ü', 'u')
        .replaceAll('ö', 'o')
        .replaceAll('Ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll('Ç', 'c');
  }
}
