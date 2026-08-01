sealed class EpisodeReorderPageResult {
  const EpisodeReorderPageResult();
}

final class EpisodeReorderSuccess extends EpisodeReorderPageResult {
  const EpisodeReorderSuccess(this.seriesContentVersion);

  final int seriesContentVersion;
}

final class EpisodeReorderConflict extends EpisodeReorderPageResult {
  const EpisodeReorderConflict();
}
