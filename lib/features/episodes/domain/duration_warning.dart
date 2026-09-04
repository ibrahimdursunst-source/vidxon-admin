/// Absolute duration-delta thresholds (ms). Mirrors edge validation.
const int durationNoticeAbsMs = 500;
const int durationWarningAbsMs = 1000;
const int durationSevereAbsMs = 2000;

/// Relative duration-delta thresholds (fraction of video duration).
const double durationNoticeRel = 0.01;
const double durationWarningRel = 0.02;
const double durationSevereRel = 0.05;

enum DurationWarningLevel {
  none,
  notice,
  warning,
  severe;

  String get apiValue => name;

  static DurationWarningLevel parse(String? raw) {
    return switch ((raw ?? 'none').trim().toLowerCase()) {
      'notice' => DurationWarningLevel.notice,
      'warning' => DurationWarningLevel.warning,
      'severe' => DurationWarningLevel.severe,
      _ => DurationWarningLevel.none,
    };
  }

  bool get isMismatch => this != DurationWarningLevel.none;

  bool get requiresExplicitOverride => this == DurationWarningLevel.severe;
}

class DurationWarningResult {
  const DurationWarningResult({
    required this.level,
    required this.deltaMs,
    required this.relative,
  });

  final DurationWarningLevel level;
  final int deltaMs;
  final double relative;

  bool get isMismatch => level.isMismatch;
}

DurationWarningLevel _classifyByAbsolute(int deltaMs) {
  if (deltaMs <= durationNoticeAbsMs) {
    return DurationWarningLevel.none;
  }
  if (deltaMs <= durationWarningAbsMs) {
    return DurationWarningLevel.notice;
  }
  if (deltaMs <= durationSevereAbsMs) {
    return DurationWarningLevel.warning;
  }
  return DurationWarningLevel.severe;
}

DurationWarningLevel _classifyByRelative(double relative) {
  if (relative <= durationNoticeRel) {
    return DurationWarningLevel.none;
  }
  if (relative <= durationWarningRel) {
    return DurationWarningLevel.notice;
  }
  if (relative <= durationSevereRel) {
    return DurationWarningLevel.warning;
  }
  return DurationWarningLevel.severe;
}

int _rank(DurationWarningLevel level) => level.index;

/// Classifies audio-vs-video duration mismatch using absolute and relative
/// deltas. Takes the more severe of the two classifications.
DurationWarningResult classifyDurationWarning({
  required int audioDurationMs,
  required int videoDurationMs,
}) {
  if (audioDurationMs <= 0 || videoDurationMs <= 0) {
    return const DurationWarningResult(
      level: DurationWarningLevel.severe,
      deltaMs: 0,
      relative: 1,
    );
  }

  final deltaMs = (audioDurationMs - videoDurationMs).abs();
  final relative = deltaMs / videoDurationMs;
  final byAbs = _classifyByAbsolute(deltaMs);
  final byRel = _classifyByRelative(relative);
  final level = _rank(byAbs) >= _rank(byRel) ? byAbs : byRel;

  return DurationWarningResult(
    level: level,
    deltaMs: deltaMs,
    relative: relative,
  );
}

/// Shown whenever duration differs from the episode. Never claim synchronized.
const String durationMismatchUserMessage =
    'Süre bölümle uyuşmuyor; yayınlamadan önce senkronizasyonu doğrulayın.';

String? durationWarningBannerMessage(DurationWarningLevel level) {
  if (!level.isMismatch) {
    return null;
  }
  return durationMismatchUserMessage;
}
