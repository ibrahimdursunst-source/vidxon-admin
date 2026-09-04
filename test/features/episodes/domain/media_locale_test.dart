import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/episodes/domain/media_locale.dart';

void main() {
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

    test('suggested locales are valid', () {
      for (final locale in MediaLocale.suggestedLocales) {
        expect(MediaLocale.isValid(locale), isTrue, reason: locale);
      }
    });
  });
}
