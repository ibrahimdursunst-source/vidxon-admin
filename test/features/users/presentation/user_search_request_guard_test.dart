import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/users/presentation/user_search_request_guard.dart';

void main() {
  group('UserSearchRequestGuard', () {
    test('ignores stale responses', () {
      final guard = UserSearchRequestGuard();

      final first = guard.beginRequest();
      final second = guard.beginRequest();

      expect(guard.shouldApplyResult(first), isFalse);
      expect(guard.shouldApplyResult(second), isTrue);
    });
  });
}
