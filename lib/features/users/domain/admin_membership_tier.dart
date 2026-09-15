enum AdminMembershipTier {
  none,
  plus,
  max;

  static AdminMembershipTier parse(dynamic value) {
    if (value == null) {
      return AdminMembershipTier.none;
    }

    switch (value.toString().trim().toLowerCase()) {
      case '':
      case 'none':
        return AdminMembershipTier.none;
      case 'plus':
        return AdminMembershipTier.plus;
      case 'max':
        return AdminMembershipTier.max;
      default:
        throw const FormatException('membership_tier is invalid.');
    }
  }

  String get storageValue {
    return switch (this) {
      AdminMembershipTier.none => 'none',
      AdminMembershipTier.plus => 'plus',
      AdminMembershipTier.max => 'max',
    };
  }
}
