/// Canonical Vidxon product locales shared by Admin media + campaign UIs.
///
/// Storage form uses underscores (`pt_BR`, `zh_Hans`). BCP-47 uses hyphens.
abstract final class VidxonProductLocales {
  static const List<String> all = [
    'tr',
    'en',
    'es',
    'pt',
    'pt_BR',
    'ar',
    'id',
    'ru',
    'fr',
    'uk',
    'ms',
    'vi',
    'zh_Hans',
    'th',
  ];

  static const Map<String, String> displayNames = {
    'tr': 'Türkçe',
    'en': 'English',
    'es': 'Español',
    'pt': 'Português',
    'pt_BR': 'Português (Brasil)',
    'ar': 'العربية',
    'id': 'Bahasa Indonesia',
    'ru': 'Русский',
    'fr': 'Français',
    'uk': 'Українська',
    'ms': 'Bahasa Melayu',
    'vi': 'Tiếng Việt',
    'zh_Hans': '简体中文',
    'th': 'ไทย',
  };

  static String displayName(String locale) => displayNames[locale] ?? locale;

  static bool contains(String locale) => all.contains(locale);
}
