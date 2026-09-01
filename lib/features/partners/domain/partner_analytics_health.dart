import 'partner_parse_helpers.dart';
import 'partner_status.dart';

class PartnerAnalyticsHealth {
  const PartnerAnalyticsHealth({
    required this.status,
    required this.generatedAt,
    required this.metricDefinitionVersion,
    required this.readyEpisodesMissingDuration,
    required this.episodeQualifiedViewsDrift,
    required this.seriesQualifiedViewsDrift,
    required this.assignmentOverlapViolations,
    required this.orphanAssignments,
    required this.warnings,
  });

  final PartnerDataIntegrityStatus status;
  final DateTime generatedAt;
  final String metricDefinitionVersion;
  final int readyEpisodesMissingDuration;
  final int episodeQualifiedViewsDrift;
  final int seriesQualifiedViewsDrift;
  final int assignmentOverlapViolations;
  final int orphanAssignments;
  final List<PartnerAnalyticsHealthWarning> warnings;

  factory PartnerAnalyticsHealth.fromJson(Map<String, dynamic> json) {
    final warningsRaw = PartnerParseHelpers.requireField(json, 'warnings');
    if (warningsRaw is! List) {
      throw const FormatException('warnings is invalid.');
    }

    return PartnerAnalyticsHealth(
      status: PartnerDataIntegrityStatus.parse(
        PartnerParseHelpers.requireField(json, 'data_integrity_status'),
      ),
      generatedAt: PartnerParseHelpers.requireUtcDateTime(
        PartnerParseHelpers.requireField(json, 'generated_at'),
        fieldName: 'generated_at',
      ),
      metricDefinitionVersion: PartnerParseHelpers.requireString(
        PartnerParseHelpers.requireField(json, 'metric_definition_version'),
        fieldName: 'metric_definition_version',
      ),
      readyEpisodesMissingDuration: PartnerParseHelpers.requireInt(
        PartnerParseHelpers.requireField(
          json,
          'ready_episodes_missing_duration',
        ),
        fieldName: 'ready_episodes_missing_duration',
      ),
      episodeQualifiedViewsDrift: PartnerParseHelpers.requireInt(
        PartnerParseHelpers.requireField(json, 'episode_qualified_views_drift'),
        fieldName: 'episode_qualified_views_drift',
      ),
      seriesQualifiedViewsDrift: PartnerParseHelpers.requireInt(
        PartnerParseHelpers.requireField(json, 'series_qualified_views_drift'),
        fieldName: 'series_qualified_views_drift',
      ),
      assignmentOverlapViolations: PartnerParseHelpers.requireInt(
        PartnerParseHelpers.requireField(json, 'assignment_overlap_violations'),
        fieldName: 'assignment_overlap_violations',
      ),
      orphanAssignments: PartnerParseHelpers.requireInt(
        PartnerParseHelpers.requireField(json, 'orphan_assignments'),
        fieldName: 'orphan_assignments',
      ),
      warnings: warningsRaw
          .map((item) {
            if (item is! Map) {
              throw const FormatException('warnings item is invalid.');
            }
            return PartnerAnalyticsHealthWarning.fromJson(
              Map<String, dynamic>.from(item),
            );
          })
          .toList(growable: false),
    );
  }
}

class PartnerAnalyticsHealthWarning {
  const PartnerAnalyticsHealthWarning({
    required this.code,
    this.count,
    this.episodeMismatchCount,
    this.seriesMismatchCount,
  });

  final String code;
  final int? count;
  final int? episodeMismatchCount;
  final int? seriesMismatchCount;

  factory PartnerAnalyticsHealthWarning.fromJson(Map<String, dynamic> json) {
    final code = PartnerParseHelpers.requireString(
      PartnerParseHelpers.requireField(json, 'code'),
      fieldName: 'code',
    );

    switch (code) {
      case 'ready_episodes_missing_duration':
      case 'assignment_overlap_detected':
      case 'orphan_assignments':
        return PartnerAnalyticsHealthWarning(
          code: code,
          count: PartnerParseHelpers.requireInt(
            PartnerParseHelpers.requireField(json, 'count'),
            fieldName: 'count',
          ),
        );
      case 'qualified_view_aggregate_drift':
        return PartnerAnalyticsHealthWarning(
          code: code,
          episodeMismatchCount: PartnerParseHelpers.requireInt(
            PartnerParseHelpers.requireField(json, 'episode_mismatch_count'),
            fieldName: 'episode_mismatch_count',
          ),
          seriesMismatchCount: PartnerParseHelpers.requireInt(
            PartnerParseHelpers.requireField(json, 'series_mismatch_count'),
            fieldName: 'series_mismatch_count',
          ),
        );
      default:
        return PartnerAnalyticsHealthWarning(
          code: code,
          count: json.containsKey('count')
              ? PartnerParseHelpers.requireInt(
                  json['count'],
                  fieldName: 'count',
                )
              : null,
          episodeMismatchCount: json.containsKey('episode_mismatch_count')
              ? PartnerParseHelpers.requireInt(
                  json['episode_mismatch_count'],
                  fieldName: 'episode_mismatch_count',
                )
              : null,
          seriesMismatchCount: json.containsKey('series_mismatch_count')
              ? PartnerParseHelpers.requireInt(
                  json['series_mismatch_count'],
                  fieldName: 'series_mismatch_count',
                )
              : null,
        );
    }
  }

  String displayMessage() {
    return switch (code) {
      'ready_episodes_missing_duration' =>
        'Hazır durumdaki bazı bölümlerde süre bilgisi eksik.'
            '${count == null ? '' : ' ($count)'}',
      'qualified_view_aggregate_drift' =>
        'Nitelikli izlenme toplamlarında uyumsuzluk: '
            'bölüm ${episodeMismatchCount ?? '—'}, '
            'dizi ${seriesMismatchCount ?? '—'}.',
      'assignment_overlap_detected' =>
        'Partner atama aralıklarında çakışma tespit edildi.'
            '${count == null ? '' : ' ($count)'}',
      'orphan_assignments' =>
        'Geçersiz Partner veya dizi referansı içeren atamalar tespit edildi.'
            '${count == null ? '' : ' ($count)'}',
      _ => 'Bilinmeyen analitik uyarısı: $code.',
    };
  }
}
