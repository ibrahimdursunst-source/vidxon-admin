import '../../users/domain/user_parse_helpers.dart';

abstract final class PartnerParseHelpers {
  static String requireUuid(dynamic value, {required String fieldName}) {
    return UserParseHelpers.requireUserId(value, fieldName: fieldName);
  }

  static String? optionalUuid(dynamic value, {required String fieldName}) {
    return UserParseHelpers.parseOptionalUserId(value, fieldName: fieldName);
  }

  static String requireString(dynamic value, {required String fieldName}) {
    return UserParseHelpers.requireString(value, fieldName: fieldName);
  }

  static String? optionalString(dynamic value) {
    return UserParseHelpers.nullableString(value);
  }

  static int requireInt(dynamic value, {required String fieldName}) {
    return UserParseHelpers.parseInt(value, fieldName: fieldName);
  }

  static double? optionalDouble(dynamic value, {required String fieldName}) {
    if (value == null) {
      return null;
    }

    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    if (value is String && value.trim().isNotEmpty) {
      final parsed = double.tryParse(value.trim());
      if (parsed != null) {
        return parsed;
      }
    }

    throw FormatException('$fieldName is invalid.');
  }

  static DateTime requireUtcDateTime(
    dynamic value, {
    required String fieldName,
  }) {
    return UserParseHelpers.requireUtcDateTime(value, fieldName: fieldName);
  }

  static DateTime? optionalUtcDateTime(dynamic value) {
    return UserParseHelpers.parseUtcDateTime(value);
  }

  static bool requireBool(dynamic value, {required String fieldName}) {
    return UserParseHelpers.requireBool(value, fieldName: fieldName);
  }

  /// Strict required field presence — missing keys throw (never default to 0).
  static dynamic requireField(Map<String, dynamic> map, String fieldName) {
    if (!map.containsKey(fieldName)) {
      throw FormatException('$fieldName is required.');
    }
    return map[fieldName];
  }

  static bool isTotalPreset(String? preset) {
    return (preset ?? '').trim().toLowerCase() == 'total';
  }

  /// TOTAL wire sentinels only. Do not treat arbitrary strings as unbounded.
  static bool isLifetimeStartSentinel(dynamic value) {
    if (value == null) {
      return true;
    }
    if (value is String) {
      return value.trim().toLowerCase() == '-infinity';
    }
    return false;
  }

  static bool isLifetimeEndSentinel(dynamic value) {
    if (value == null) {
      return true;
    }
    if (value is String) {
      return value.trim().toLowerCase() == 'infinity';
    }
    return false;
  }
}
