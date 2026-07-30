bool shouldSkipDebouncedUserSearch({
  required String query,
  required String activeQuery,
  required bool isLoading,
  required bool isLoadingMore,
}) {
  return query == activeQuery && !isLoading && !isLoadingMore;
}

bool shouldSkipDuplicateInFlightSearch({
  required String query,
  required String? inFlightQuery,
  required bool isLoading,
  required bool reset,
}) {
  return reset && isLoading && inFlightQuery == query;
}
