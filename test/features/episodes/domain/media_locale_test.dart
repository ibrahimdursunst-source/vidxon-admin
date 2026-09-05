import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/core/locale/vidxon_product_locales.dart';
import 'package:vidxon_admin/features/episodes/domain/media_locale.dart';

void main() {
  group('VidxonProductLocales', () {
    test('all has exactly 14 unique entries', () {
      expect(VidxonProductLocales.all, hasLength(14));
      expect(
        VidxonProductLocales.all.toSet(),
        hasLength(VidxonProductLocales.all.length),
      );
    });

    test('includes expanded product locales', () {
      expect(
        VidxonProductLocales.all,
        containsAll(['ru', 'fr', 'uk', 'ms', 'vi', 'zh_Hans', 'th']),
      );
    });

    test('excludes zh_Hant and ua', () {
      expect(VidxonProductLocales.all, isNot(contains('zh_Hant')));
      expect(VidxonProductLocales.all, isNot(contains('ua')));
    });

    test('pt and pt_BR are both present and distinct', () {
      expect(VidxonProductLocales.all, contains('pt'));
      expect(VidxonProductLocales.all, contains('pt_BR'));
      expect('pt', isNot(equals('pt_BR')));
    });
  });

  group('MediaLocale', () {
    test('accepts language and language_REGION forms', () {
      expect(MediaLocale.isValid('tr'), isTrue);
      expect(MediaLocale.isValid('en'), isTrue);
      expect(MediaLocale.isValid('pt'), isTrue);
      expect(MediaLocale.isValid('pt_BR'), isTrue);
      expect(MediaLocale.isValid('ar'), isTrue);
    });

    test('rejects invalid forms and treats pt vs pt_BR as distinct', () {
      expect(MediaLocale.isValid('PT'), isFalse);
      expect(MediaLocale.isValid('pt-BR'), isFalse);
      expect(MediaLocale.isValid('pt_br'), isFalse);
      expect(MediaLocale.isValid('english'), isFalse);
      expect(MediaLocale.normalizeOrNull('pt'), isNot(equals('pt_BR')));
    });

    test('suggestedLocales equals VidxonProductLocales.all', () {
      expect(MediaLocale.suggestedLocales, VidxonProductLocales.all);
    });

    test('suggested locales are valid', () {
      for (final locale in MediaLocale.suggestedLocales) {
        expect(MediaLocale.isValid(locale), isTrue, reason: locale);
      }
    });

    test('zh_Hans storage form is valid; BCP-47 hyphen form is not', () {
      expect(MediaLocale.isValid('zh_Hans'), isTrue);
      expect(MediaLocale.isValid('zh-Hans'), isFalse);
      // Language-only matches the pattern but is not in suggestedLocales.
      expect(MediaLocale.isValid('zh'), isTrue);
      expect(MediaLocale.suggestedLocales, isNot(contains('zh')));
    });
  });
}
