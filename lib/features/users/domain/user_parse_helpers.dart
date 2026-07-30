abstract final class UserParseHelpers {
  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static String requireUserId(dynamic value, {String fieldName = 'user_id'}) {
    if (value == null) {
      throw FormatException('$fieldName is required.');
    }

    final parsed = value.toString().trim();
    if (!_uuidPattern.hasMatch(parsed)) {
      throw FormatException('$fieldName is invalid.');
    }

    return parsed.toLowerCase();
  }

  static int parseInt(dynamic value, {required String fieldName}) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String && value.trim().isNotEmpty) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null) {
        return parsed;
      }
    }

    throw FormatException('$fieldName is invalid.');
  }

  static int parseBigIntField(dynamic value, {required String fieldName}) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String && value.trim().isNotEmpty) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null) {
        return parsed;
      }
    }

    throw FormatException('$fieldName is invalid.');
  }

  static DateTime? parseUtcDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    final parsed = DateTime.tryParse(value.toString().trim());
    if (parsed == null) {
      return null;
    }

    return parsed.toUtc();
  }

  static DateTime requireUtcDateTime(
    dynamic value, {
    required String fieldName,
  }) {
    final parsed = parseUtcDateTime(value);
    if (parsed == null) {
      throw FormatException('$fieldName is invalid.');
    }

    return parsed;
  }

  static String? nullableString(dynamic value) {
    if (value == null) {
      return null;
    }

    final trimmed = value.toString().trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static int? parseNullableInt(dynamic value, {required String fieldName}) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String && value.trim().isNotEmpty) {
      return int.tryParse(value.trim());
    }

    throw FormatException('$fieldName is invalid.');
  }

  static String? parseOptionalUserId(
    dynamic value, {
    String fieldName = 'user_id',
  }) {
    if (value == null) {
      return null;
    }

    final trimmed = value.toString().trim();
    if (trimmed.isEmpty) {
      return null;
    }

    if (!_uuidPattern.hasMatch(trimmed)) {
      throw FormatException('$fieldName is invalid.');
    }

    return trimmed.toLowerCase();
  }

  static String? parseNullableEmail(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is! String) {
      throw FormatException('email is invalid.');
    }

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String? parseNullableDisplayName(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is! String) {
      throw FormatException('display_name is invalid.');
    }

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String requireString(dynamic value, {required String fieldName}) {
    final parsed = nullableString(value);
    if (parsed == null) {
      throw FormatException('$fieldName is required.');
    }

    return parsed;
  }
}

String formatUserDisplayName({String? displayName, String? email}) {
  final trimmedDisplayName = displayName?.trim();
  if (trimmedDisplayName != null && trimmedDisplayName.isNotEmpty) {
    return trimmedDisplayName;
  }

  final trimmedEmail = email?.trim();
  if (trimmedEmail != null && trimmedEmail.isNotEmpty) {
    return trimmedEmail;
  }

  return 'Anonim Kullanıcı';
}

String formatUserEmailLabel(String? email) {
  final trimmed = email?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return 'E-posta yok';
  }

  return trimmed;
}

String shortenUserId(String userId) {
  final trimmed = userId.trim();
  if (trimmed.length <= 12) {
    return trimmed;
  }

  return '${trimmed.substring(0, 8)}…';
}

String formatAccountStatusLabel(String? status) {
  if (status == null || status.trim().isEmpty) {
    return 'Bilinmiyor';
  }

  return switch (status.trim().toLowerCase()) {
    'active' => 'Aktif',
    'unconfirmed' => 'Onaylanmamış',
    'suspended' => 'Askıda',
    'banned' => 'Yasaklı',
    'inactive' => 'Pasif',
    'disabled' => 'Devre Dışı',
    _ => status.trim(),
  };
}

String formatUserDateTime(DateTime? value) {
  if (value == null) {
    return '—';
  }

  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year;
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');

  return '$day.$month.$year $hour:$minute';
}
