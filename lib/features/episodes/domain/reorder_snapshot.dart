import 'admin_episode.dart';

/// Coherent reorder state: active episode ordering and series content version
/// loaded together from the same fetch generation.
class ReorderSnapshot {
  const ReorderSnapshot({
    required this.seriesId,
    required this.activeEpisodes,
    required this.contentVersion,
  });

  final String seriesId;
  final List<AdminEpisode> activeEpisodes;
  final int contentVersion;

  List<String> get orderedEpisodeIds =>
      activeEpisodes.map((episode) => episode.id).toList(growable: false);
}
