enum AdminRole {
  admin('admin'),
  superAdmin('super_admin');

  const AdminRole(this.storageValue);

  final String storageValue;

  String get labelTurkish => switch (this) {
    AdminRole.admin => 'Admin',
    AdminRole.superAdmin => 'Super Admin',
  };

  static AdminRole? parseNullable(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is! String) {
      throw FormatException('admin_role is invalid.');
    }

    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    return switch (trimmed) {
      'admin' => AdminRole.admin,
      'super_admin' => AdminRole.superAdmin,
      _ => throw FormatException('admin_role is unknown.'),
    };
  }

  static AdminRole parseRequired(dynamic value, {String fieldName = 'role'}) {
    if (value == null) {
      throw FormatException('$fieldName is required.');
    }

    if (value is! String || value.trim().isEmpty) {
      throw FormatException('$fieldName is invalid.');
    }

    return switch (value.trim()) {
      'admin' => AdminRole.admin,
      'super_admin' => AdminRole.superAdmin,
      _ => throw FormatException('$fieldName is unknown.'),
    };
  }
}

String formatAdminRoleLabel(AdminRole? role) {
  if (role == null) {
    return '';
  }

  return role.labelTurkish;
}
