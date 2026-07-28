import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/core/utils/slug_helper.dart';

void main() {
  group('SlugHelper.generateFromTitle', () {
    test('converts Turkish characters to ASCII', () {
      expect(
        SlugHelper.generateFromTitle('Güzel Şehir Çocuğu'),
        'guzel-sehir-cocugu',
      );
    });

    test('handles dotted and dotless i', () {
      expect(SlugHelper.generateFromTitle('Işık Işığı'), 'isik-isigi');
    });

    test('collapses multiple spaces and symbols into single hyphen', () {
      expect(
        SlugHelper.generateFromTitle('  Hello   ---  World!!  '),
        'hello-world',
      );
    });

    test('removes leading and trailing hyphens', () {
      expect(SlugHelper.generateFromTitle('--- Test ---'), 'test');
    });
  });

  group('SlugHelper.isValid', () {
    test('accepts valid slug format', () {
      expect(SlugHelper.isValid('my-series-2'), isTrue);
    });

    test('rejects empty slug', () {
      expect(SlugHelper.isValid(''), isFalse);
      expect(SlugHelper.isValid('   '), isFalse);
    });

    test('rejects invalid slug format', () {
      expect(SlugHelper.isValid('-invalid'), isFalse);
      expect(SlugHelper.isValid('invalid-'), isFalse);
      expect(SlugHelper.isValid('UPPERCASE'), isFalse);
      expect(SlugHelper.isValid('bad slug'), isFalse);
    });
  });
}
