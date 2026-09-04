import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/episodes/domain/duration_warning.dart';

void main() {
  group('classifyDurationWarning', () {
    test('none when within notice absolute threshold', () {
      final result = classifyDurationWarning(
        audioDurationMs: 100_000,
        videoDurationMs: 100_400,
      );
      expect(result.level, DurationWarningLevel.none);
      expect(result.deltaMs, 400);
    });

    test('notice for ~0.8% relative / 800ms abs', () {
      final result = classifyDurationWarning(
        audioDurationMs: 100_800,
        videoDurationMs: 100_000,
      );
      expect(result.level, DurationWarningLevel.notice);
    });

    test('warning for ~1.5s absolute delta', () {
      final result = classifyDurationWarning(
        audioDurationMs: 101_500,
        videoDurationMs: 100_000,
      );
      expect(result.level, DurationWarningLevel.warning);
    });

    test('severe for large absolute delta', () {
      final result = classifyDurationWarning(
        audioDurationMs: 110_000,
        videoDurationMs: 100_000,
      );
      expect(result.level, DurationWarningLevel.severe);
      expect(result.level.requiresExplicitOverride, isTrue);
    });

    test('invalid durations classify as severe', () {
      final result = classifyDurationWarning(
        audioDurationMs: 0,
        videoDurationMs: 100_000,
      );
      expect(result.level, DurationWarningLevel.severe);
    });
  });

  group('durationWarningBannerMessage', () {
    test('never claims synchronized; mismatch shows verify message', () {
      for (final level in DurationWarningLevel.values) {
        final message = durationWarningBannerMessage(level);
        if (level == DurationWarningLevel.none) {
          expect(message, isNull);
        } else {
          expect(message, durationMismatchUserMessage);
          expect(message!.toLowerCase(), isNot(contains('senkronize')));
          expect(message.toLowerCase(), isNot(contains('synchronized')));
        }
      }
    });
  });
}
