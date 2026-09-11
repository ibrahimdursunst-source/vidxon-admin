/// Explicit QA isolation. Empty allowlist must never become broadcast.
abstract final class CampaignTestTargeting {
  static String? validate({
    required bool testOnly,
    String? testUserId,
  }) {
    if (!testOnly) {
      return null;
    }
    final id = testUserId?.trim() ?? '';
    if (id.isEmpty) {
      return 'test_user_required';
    }
    return null;
  }

  static ({bool testOnly, String? testUserId}) persist({
    required bool testOnly,
    String? testUserId,
  }) {
    if (!testOnly) {
      return (testOnly: false, testUserId: null);
    }
    final id = testUserId?.trim() ?? '';
    return (testOnly: true, testUserId: id.isEmpty ? null : id);
  }
}
