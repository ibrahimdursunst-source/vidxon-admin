import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/episodes/domain/cloudflare_stream_status.dart';

void main() {
  group('CloudflareStreamStatus.parse', () {
    test('parses known values', () {
      expect(CloudflareStreamStatus.parse('none'), CloudflareStreamStatus.none);
      expect(
        CloudflareStreamStatus.parse('processing'),
        CloudflareStreamStatus.processing,
      );
      expect(
        CloudflareStreamStatus.parse('ready'),
        CloudflareStreamStatus.ready,
      );
      expect(
        CloudflareStreamStatus.parse('error'),
        CloudflareStreamStatus.error,
      );
    });

    test('defaults null and empty to none', () {
      expect(CloudflareStreamStatus.parse(null), CloudflareStreamStatus.none);
      expect(CloudflareStreamStatus.parse(''), CloudflareStreamStatus.none);
    });

    test('throws on unknown status', () {
      expect(
        () => CloudflareStreamStatus.parse('broken'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
