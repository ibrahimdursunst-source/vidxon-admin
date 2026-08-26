import 'partner_parse_helpers.dart';
import 'partner_status.dart';

/// Strict Partner analytics report. Missing required fields throw.
/// Callers must never convert parse/load failures into a zero report.
class PartnerAnalyticsReport {
  const PartnerAnalyticsReport({
    required this.qualifiedViews,
    required this.uniqueViewers,
    required this.validatedWatchSeconds,
    required this.qualifiedSessions,
    required this.completedSessions,
    required this.reportStart,
    required this.reportEnd,
    required this.asOf,
    required this.metricVersion,
    required this.generatedAt,
    required this.reportingTimezone,
    required this.episodes,
    this.completionRate,
    this.preset,
    this.dataIntegrityStatus,
    this.partnerId,
    this.seriesId,
    this.episodeTotalCount,
    this.episodeLimit,
    this.episodeOffset,
    this.episodeSnapshotAsOf,
  });

  final int qualifiedViews;
  final int uniqueViewers;
  final int validatedWatchSeconds;
  final int qualifiedSessions;
  final int completedSessions;

  /// Null when denominator (qualified_sessions) is 0. UI must show "—", not 0%.
  final double? completionRate;

  final DateTime reportStart;
  final DateTime reportEnd;
  final DateTime asOf;
  final DateTime generatedAt;
  final String metricVersion;
  final String reportingTimezone;
  final String? preset;
  final PartnerDataIntegrityStatus? dataIntegrityStatus;
  final String? partnerId;
  final String? seriesId;
  final List<PartnerEpisodeAnalyticsRow> episodes;
  final int? episodeTotalCount;
  final int? episodeLimit;
  final int? episodeOffset;
  final DateTime? episodeSnapshotAsOf;

  bool get hasMoreEpisodes {
    final total = episodeTotalCount;
    if (total == null) return false;
    return episodes.length < total;
  }

  PartnerAnalyticsReport mergeEpisodePage(PartnerAnalyticsReport page) {
    final seen = <String>{for (final row in episodes) row.episodeId};
    final merged = [...episodes];
    for (final row in page.episodes) {
      if (seen.add(row.episodeId)) {
        merged.add(row);
      }
    }
    merged.sort((a, b) {
      final an = a.episodeNumber ?? 1 << 30;
      final bn = b.episodeNumber ?? 1 << 30;
      final byNumber = an.compareTo(bn);
      if (byNumber != 0) return byNumber;
      return a.episodeId.compareTo(b.episodeId);
    });
    return PartnerAnalyticsReport(
      qualifiedViews: qualifiedViews,
      uniqueViewers: uniqueViewers,
      validatedWatchSeconds: validatedWatchSeconds,
      qualifiedSessions: qualifiedSessions,
      completedSessions: completedSessions,
      completionRate: completionRate,
      reportStart: reportStart,
      reportEnd: reportEnd,
      asOf: asOf,
      metricVersion: metricVersion,
      generatedAt: generatedAt,
      reportingTimezone: reportingTimezone,
      preset: preset,
      dataIntegrityStatus: dataIntegrityStatus,
      partnerId: partnerId,
      seriesId: seriesId,
      episodes: List.unmodifiable(merged),
      episodeTotalCount: page.episodeTotalCount ?? episodeTotalCount,
      episodeLimit: page.episodeLimit ?? episodeLimit,
      episodeOffset: page.episodeOffset ?? episodeOffset,
      episodeSnapshotAsOf: episodeSnapshotAsOf ?? page.episodeSnapshotAsOf,
    );
  }

  factory PartnerAnalyticsReport.fromJson(Map<String, dynamic> json) {
    final completionRaw = PartnerParseHelpers.requireField(
      json,
      'completion_rate',
    );

    return PartnerAnalyticsReport(
      qualifiedViews: PartnerParseHelpers.requireInt(
        PartnerParseHelpers.requireField(json, 'qualified_views'),
        fieldName: 'qualified_views',
      ),
      uniqueViewers: PartnerParseHelpers.requireInt(
        PartnerParseHelpers.requireField(json, 'unique_viewers'),
        fieldName: 'unique_viewers',
      ),
      validatedWatchSeconds: PartnerParseHelpers.requireInt(
        PartnerParseHelpers.requireField(json, 'validated_watch_seconds'),
        fieldName: 'validated_watch_seconds',
      ),
      qualifiedSessions: PartnerParseHelpers.requireInt(
        PartnerParseHelpers.requireField(json, 'qualified_sessions'),
        fieldName: 'qualified_sessions',
      ),
      completedSessions: PartnerParseHelpers.requireInt(
        PartnerParseHelpers.requireField(json, 'completed_sessions'),
        fieldName: 'completed_sessions',
      ),
      completionRate: completionRaw == null
          ? null
          : PartnerParseHelpers.optionalDouble(
              completionRaw,
              fieldName: 'completion_rate',
            ),
      reportStart: PartnerParseHelpers.requireUtcDateTime(
        _requireAliased(json, const ['resolved_start', 'report_start']),
        fieldName: 'resolved_start',
      ),
      reportEnd: PartnerParseHelpers.requireUtcDateTime(
        _requireAliased(json, const ['resolved_end', 'report_end']),
        fieldName: 'resolved_end',
      ),
      asOf: PartnerParseHelpers.requireUtcDateTime(
        PartnerParseHelpers.requireField(json, 'as_of'),
        fieldName: 'as_of',
      ),
      generatedAt: PartnerParseHelpers.requireUtcDateTime(
        PartnerParseHelpers.requireField(json, 'generated_at'),
        fieldName: 'generated_at',
      ),
      metricVersion: PartnerParseHelpers.requireString(
        _requireAliased(json, const [
          'metric_definition_version',
          'metric_version',
        ]),
        fieldName: 'metric_definition_version',
      ),
      reportingTimezone: PartnerParseHelpers.requireString(
        PartnerParseHelpers.requireField(json, 'reporting_timezone'),
        fieldName: 'reporting_timezone',
      ),
      preset: PartnerParseHelpers.optionalString(json['preset']),
      dataIntegrityStatus: PartnerDataIntegrityStatus.tryParse(
        json['data_integrity_status'],
      ),
      partnerId: PartnerParseHelpers.optionalUuid(
        json['partner_id'],
        fieldName: 'partner_id',
      ),
      seriesId: PartnerParseHelpers.optionalUuid(
        json['series_id'],
        fieldName: 'series_id',
      ),
      episodes: _parseEpisodes(json),
      episodeTotalCount: json.containsKey('episode_total_count')
          ? PartnerParseHelpers.requireInt(
              json['episode_total_count'],
              fieldName: 'episode_total_count',
            )
          : null,
      episodeLimit: json.containsKey('episode_limit')
          ? PartnerParseHelpers.requireInt(
              json['episode_limit'],
              fieldName: 'episode_limit',
            )
          : null,
      episodeOffset: json.containsKey('episode_offset')
          ? PartnerParseHelpers.requireInt(
              json['episode_offset'],
              fieldName: 'episode_offset',
            )
          : null,
      episodeSnapshotAsOf: json['episode_snapshot_as_of'] == null
          ? null
          : PartnerParseHelpers.requireUtcDateTime(
              json['episode_snapshot_as_of'],
              fieldName: 'episode_snapshot_as_of',
            ),
    );
  }

  static dynamic _requireAliased(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      if (json.containsKey(key)) {
        return json[key];
      }
    }
    throw FormatException('${keys.first} is required.');
  }

  static List<PartnerEpisodeAnalyticsRow> _parseEpisodes(
    Map<String, dynamic> json,
  ) {
    final raw = json.containsKey('episodes')
        ? json['episodes']
        : json.containsKey('episode_breakdown')
        ? json['episode_breakdown']
        : throw const FormatException('episodes is required.');

    if (raw is! List) {
      throw const FormatException('episodes is invalid.');
    }

    return raw.map((item) {
      if (item is! Map) {
        throw const FormatException('episodes item is invalid.');
      }
      return PartnerEpisodeAnalyticsRow.fromJson(
        Map<String, dynamic>.from(item),
      );
    }).toList(growable: false);
  }
}

class PartnerEpisodeAnalyticsRow {
  const PartnerEpisodeAnalyticsRow({
    required this.episodeId,
    required this.qualifiedViews,
    required this.uniqueViewers,
    required this.validatedWatchSeconds,
    required this.qualifiedSessions,
    required this.completedSessions,
    this.completionRate,
    this.episodeNumber,
    this.title,
  });

  final String episodeId;
  final int? episodeNumber;
  final String? title;
  final int qualifiedViews;
  final int uniqueViewers;
  final int validatedWatchSeconds;
  final int qualifiedSessions;
  final int completedSessions;
  final double? completionRate;

  factory PartnerEpisodeAnalyticsRow.fromJson(Map<String, dynamic> json) {
    final completionRaw = PartnerParseHelpers.requireField(
      json,
      'completion_rate',
    );

    return PartnerEpisodeAnalyticsRow(
      episodeId: PartnerParseHelpers.requireUuid(
        PartnerParseHelpers.requireField(json, 'episode_id'),
        fieldName: 'episode_id',
      ),
      episodeNumber: json.containsKey('episode_number') &&
              json['episode_number'] != null
          ? PartnerParseHelpers.requireInt(
              json['episode_number'],
              fieldName: 'episode_number',
            )
          : null,
      title: PartnerParseHelpers.optionalString(json['title']),
      qualifiedViews: PartnerParseHelpers.requireInt(
        PartnerParseHelpers.requireField(json, 'qualified_views'),
        fieldName: 'qualified_views',
      ),
      uniqueViewers: PartnerParseHelpers.requireInt(
        PartnerParseHelpers.requireField(json, 'unique_viewers'),
        fieldName: 'unique_viewers',
      ),
      validatedWatchSeconds: PartnerParseHelpers.requireInt(
        PartnerParseHelpers.requireField(json, 'validated_watch_seconds'),
        fieldName: 'validated_watch_seconds',
      ),
      qualifiedSessions: PartnerParseHelpers.requireInt(
        PartnerParseHelpers.requireField(json, 'qualified_sessions'),
        fieldName: 'qualified_sessions',
      ),
      completedSessions: PartnerParseHelpers.requireInt(
        PartnerParseHelpers.requireField(json, 'completed_sessions'),
        fieldName: 'completed_sessions',
      ),
      completionRate: completionRaw == null
          ? null
          : PartnerParseHelpers.optionalDouble(
              completionRaw,
              fieldName: 'completion_rate',
            ),
    );
  }
}
