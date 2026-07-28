import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/media/domain/poster_file.dart';

void main() {
  group('PosterFileValidator.contentTypeForExtension', () {
    test('maps jpg and jpeg to image/jpeg', () {
      expect(PosterFileValidator.contentTypeForExtension('jpg'), 'image/jpeg');
      expect(PosterFileValidator.contentTypeForExtension('jpeg'), 'image/jpeg');
      expect(PosterFileValidator.contentTypeForExtension('JPEG'), 'image/jpeg');
    });

    test('maps png and webp correctly', () {
      expect(PosterFileValidator.contentTypeForExtension('png'), 'image/png');
      expect(PosterFileValidator.contentTypeForExtension('webp'), 'image/webp');
    });

    test('returns null for unsupported extension', () {
      expect(PosterFileValidator.contentTypeForExtension('gif'), isNull);
    });
  });

  group('PosterFileValidator.isWithinSizeLimit', () {
    test('accepts positive sizes up to 10 MiB', () {
      expect(PosterFileValidator.isWithinSizeLimit(1), isTrue);
      expect(
        PosterFileValidator.isWithinSizeLimit(PosterFileValidator.maxSizeBytes),
        isTrue,
      );
    });

    test('rejects empty or oversized files', () {
      expect(PosterFileValidator.isWithinSizeLimit(0), isFalse);
      expect(
        PosterFileValidator.isWithinSizeLimit(
          PosterFileValidator.maxSizeBytes + 1,
        ),
        isFalse,
      );
    });
  });

  group('PosterFileValidator.validate', () {
    test('rejects files without extension', () {
      expect(
        () => PosterFileValidator.validate(
          bytes: Uint8List.fromList([1, 2, 3]),
          fileName: 'poster',
        ),
        throwsA(isA<PosterFileValidationException>()),
      );
    });

    test('rejects oversized files', () {
      expect(
        () => PosterFileValidator.validate(
          bytes: Uint8List(PosterFileValidator.maxSizeBytes + 1),
          fileName: 'poster.jpg',
        ),
        throwsA(isA<PosterFileValidationException>()),
      );
    });

    test('accepts valid poster file', () {
      final poster = PosterFileValidator.validate(
        bytes: Uint8List.fromList([1, 2, 3]),
        fileName: 'poster.PNG',
      );

      expect(poster.contentType, 'image/png');
      expect(poster.extension, 'png');
    });
  });
}
