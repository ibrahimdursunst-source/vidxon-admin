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

  static String _two(int value) => value.toString().padLeft(2, '0');

  static DateTime parseUtc(String raw) {
    final parsed = DateTime.parse(raw);
    return parsed.isUtc ? parsed : parsed.toUtc();
  }

  static DateTime? tryParseUtc(Object? raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString())?.toUtc();
  }

  static DateTime utcToLocal(DateTime value) => value.toUtc().toLocal();

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
