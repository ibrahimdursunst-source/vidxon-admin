class UserSearchRequestGuard {
  int _generation = 0;

  int beginRequest() => ++_generation;

  bool shouldApplyResult(int generation) => generation == _generation;
}
