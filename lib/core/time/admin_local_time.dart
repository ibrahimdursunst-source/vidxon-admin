import 'package:flutter/material.dart';

/// Converts UTC storage timestamps to the operator's browser/device local time.
/// Database values stay UTC. Do not hardcode a country timezone.
class AdminLocalTime {
  const AdminLocalTime._();

  static const _enMonths = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static final _iso = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})[T ](\d{2}):(\d{2})(?::(\d{2})(?:\.(\d+))?)?(Z|[+-]\d{2}:?\d{2})?',
  );

  static String _two(int value) => value.toString().padLeft(2, '0');

  static DateTime parseUtc(String raw) {
    final parsed = tryParseUtc(raw);
    if (parsed == null) {
      throw FormatException('Invalid UTC timestamp', raw);
    }
    return parsed;
  }

  /// Interprets API/DB timestamps as UTC instants.
  ///
  /// Timezone-less values and `Z` / `+00:00` keep the numeric wall clock as UTC.
  /// That avoids Flutter-web `DateTime.parse` treating UTC numbers as local,
  /// which would display 16:06Z as 16:06 in UTC+3 instead of 19:06.
  static DateTime? tryParseUtc(Object? raw) {
    if (raw == null) return null;
    if (raw is DateTime) {
      if (raw.isUtc) return raw;
      return DateTime.utc(
        raw.year,
        raw.month,
        raw.day,
        raw.hour,
        raw.minute,
        raw.second,
        raw.millisecond,
        raw.microsecond,
      );
    }

    final text = raw.toString().trim();
    if (text.isEmpty) return null;
    final match = _iso.firstMatch(text);
    if (match == null) {
      return DateTime.tryParse(text)?.toUtc();
    }

    final year = int.parse(match[1]!);
    final month = int.parse(match[2]!);
    final day = int.parse(match[3]!);
    final hour = int.parse(match[4]!);
    final minute = int.parse(match[5]!);
    final second = int.parse(match[6] ?? '0');
    var millisecond = 0;
    var microsecond = 0;
    final fraction = match[7];
    if (fraction != null && fraction.isNotEmpty) {
    final padded = '${fraction}000000'.substring(0, 6);
      millisecond = int.parse(padded.substring(0, 3));
      microsecond = int.parse(padded.substring(3, 6));
    }

    var utc = DateTime.utc(
      year,
      month,
      day,
      hour,
      minute,
      second,
      millisecond,
      microsecond,
    );
    final tz = match[8];
    if (tz != null && tz.isNotEmpty && tz != 'Z') {
      final sign = tz.startsWith('-') ? -1 : 1;
      final digits = tz.substring(1).replaceAll(':', '');
      if (digits.length >= 2) {
        final tzHour = int.parse(digits.substring(0, 2));
        final tzMinute =
            digits.length >= 4 ? int.parse(digits.substring(2, 4)) : 0;
        utc = utc.subtract(
          Duration(hours: sign * tzHour, minutes: sign * tzMinute),
        );
      }
    }
    return utc;
  }

  static DateTime utcToLocal(DateTime value) {
    final utc = value.isUtc
        ? value
        : DateTime.utc(
            value.year,
            value.month,
            value.day,
            value.hour,
            value.minute,
            value.second,
            value.millisecond,
            value.microsecond,
          );
    return utc.toLocal();
  }

  /// Interprets a picker DateTime as local wall time, then converts to UTC.
  static DateTime localToUtc(DateTime localWallTime) {
    final local = DateTime(
      localWallTime.year,
      localWallTime.month,
      localWallTime.day,
      localWallTime.hour,
      localWallTime.minute,
      localWallTime.second,
    );
    return local.toUtc();
  }

  static DateTime utcToLocalPicker(DateTime utc) => utcToLocal(utc);

  static String format(DateTime utc, Locale locale) {
    final local = utcToLocal(utc);
    if (locale.languageCode == 'tr') {
      return '${_two(local.day)}.${_two(local.month)}.${local.year} ${_two(local.hour)}:${_two(local.minute)}';
    }
    final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '${_enMonths[local.month - 1]} ${local.day}, ${local.year}, $hour12:${_two(local.minute)} $period';
  }

  static bool looksLikeRawUtcIso(String value) {
    return value.contains('T') &&
        (value.endsWith('Z') || value.contains('+00:00'));
  }
}
