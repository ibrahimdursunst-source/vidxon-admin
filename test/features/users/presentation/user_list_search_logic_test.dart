import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/users/presentation/user_list_search_logic.dart';

void main() {
  group('shouldSkipDebouncedUserSearch', () {
    test('skips when query already loaded', () {
      expect(
        shouldSkipDebouncedUserSearch(
          query: '',
          activeQuery: '',
          isLoading: false,
          isLoadingMore: false,
        ),
        isTrue,
      );
    });

    test('does not skip when query changed', () {
      expect(
        shouldSkipDebouncedUserSearch(
          query: 'user@example.com',
          activeQuery: '',
          isLoading: false,
          isLoadingMore: false,
        ),
        isFalse,
      );
    });
  });

  group('shouldSkipDuplicateInFlightSearch', () {
    test('skips duplicate in-flight search for same query', () {
      expect(
        shouldSkipDuplicateInFlightSearch(
          query: '',
          inFlightQuery: '',
          isLoading: true,
          reset: true,
        ),
        isTrue,
      );
    });

    test('allows search when previous request finished', () {
      expect(
        shouldSkipDuplicateInFlightSearch(
          query: '',
          inFlightQuery: '',
          isLoading: false,
          reset: true,
        ),
        isFalse,
      );
    });
  });
}
