import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/partners/domain/partner_analytics_report.dart';
import 'package:vidxon_admin/features/partners/domain/partner_metric_copy.dart';
import 'package:vidxon_admin/features/partners/domain/partner_rpc_params.dart';
import 'package:vidxon_admin/features/partners/domain/partner_status.dart';

Map<String, dynamic> validAnalyticsJson({
  int qualifiedViews = 10,
  int uniqueViewers = 4,
  int validatedWatchSeconds = 1200,
  int qualifiedSessions = 8,
  int completedSessions = 4,
  double? completionRate = 0.5,
  bool includeCompletionRateKey = true,
  bool includeQualifiedViews = true,
  bool includeEpisodes = true,
}) {
  final json = <String, dynamic>{
    'unique_viewers': uniqueViewers,
    'validated_watch_seconds': validatedWatchSeconds,
    'qualified_sessions': qualifiedSessions,
    'completed_sessions': completedSessions,
    'report_start': '2026-08-01T00:00:00.000Z',
    'report_end': '2026-08-08T00:00:00.000Z',
    'as_of': '2026-08-08T12:00:00.000Z',
    'generated_at': '2026-08-08T12:00:01.000Z',
    'metric_version': 'qualified_view_v1',
    'reporting_timezone': 'UTC',
    'preset': 'last_7_days',
    'data_integrity_status': 'healthy',
  };

  if (includeQualifiedViews) {
    json['qualified_views'] = qualifiedViews;
  }

  if (includeCompletionRateKey) {
    json['completion_rate'] = completionRate;
  }

  if (includeEpisodes) {
    json['episodes'] = [
      {
        'episode_id': '11111111-1111-1111-1111-111111111111',
        'episode_number': 1,
        'title': 'Bölüm 1',
        'qualified_views': qualifiedViews,
        'unique_viewers': uniqueViewers,
        'validated_watch_seconds': validatedWatchSeconds,
        'qualified_sessions': qualifiedSessions,
        'completed_sessions': completedSessions,
        'completion_rate': completionRate,
      },
    ];
  }

  return json;
}

void main() {
  group('PartnerAnalyticsReport strict parse', () {
    test('parses a complete valid report including zero metrics', () {
      final report = PartnerAnalyticsReport.fromJson(
        validAnalyticsJson(
          qualifiedViews: 0,
          uniqueViewers: 0,
          validatedWatchSeconds: 0,
          qualifiedSessions: 0,
          completedSessions: 0,
          completionRate: null,
        ),
      );

      expect(report.qualifiedViews, 0);
      expect(report.uniqueViewers, 0);
      expect(report.validatedWatchSeconds, 0);
      expect(report.completionRate, isNull);
      expect(PartnerMetricCopy.formatCompletionRate(report.completionRate), '—');
      expect(report.metricVersion, 'qualified_view_v1');
      expect(report.episodes, hasLength(1));
    });

    test('missing required qualified_views throws (never defaults to 0)', () {
      expect(
        () => PartnerAnalyticsReport.fromJson(
          validAnalyticsJson(includeQualifiedViews: false),
        ),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('qualified_views'),
          ),
        ),
      );
    });

    test('missing required completion_rate key throws', () {
      expect(
        () => PartnerAnalyticsReport.fromJson(
          validAnalyticsJson(includeCompletionRateKey: false),
        ),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('completion_rate'),
          ),
        ),
      );
    });

    test('missing episodes throws', () {
      expect(
        () => PartnerAnalyticsReport.fromJson(
          validAnalyticsJson(includeEpisodes: false),
        ),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('episodes'),
          ),
        ),
      );
    });

    test('null completion_rate is allowed and formats as em dash', () {
      final report = PartnerAnalyticsReport.fromJson(
        validAnalyticsJson(
          qualifiedSessions: 0,
          completedSessions: 0,
          completionRate: null,
        ),
      );

      expect(report.completionRate, isNull);
      expect(PartnerMetricCopy.formatCompletionRate(null), '—');
      expect(PartnerMetricCopy.formatCompletionRate(0), '%0.0');
    });

    test('renamed/missing as_of throws', () {
      final json = validAnalyticsJson()..remove('as_of');
      expect(
        () => PartnerAnalyticsReport.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('catch path must not synthesize a zero report from bad JSON', () {
      PartnerAnalyticsReport? report;
      Object? caught;

      try {
        report = PartnerAnalyticsReport.fromJson({'ok': true});
      } catch (error) {
        caught = error;
      }

      expect(caught, isA<FormatException>());
      expect(report, isNull);
      // Explicitly prove we did not fall back to zeros:
      expect(report?.qualifiedViews, isNull);
    });
  });

  group('Partner RPC params', () {
    test('create uses p_display_name and p_legal_name', () {
      expect(
        buildPartnerCreateRpcParams(
          displayName: ' Studio X ',
          legalName: ' Studio X LLC ',
        ),
        {
          'p_display_name': 'Studio X',
          'p_legal_name': 'Studio X LLC',
        },
      );
    });

    test('set series partner allows null partner id', () {
      expect(
        buildSetSeriesPartnerRpcParams(
          seriesId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
          partnerId: null,
          expectedContentVersion: 3,
        ),
        {
          'p_series_id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
          'p_partner_id': null,
          'p_expected_content_version': 3,
        },
      );
    });

    test('analytics params include preset and custom bounds', () {
      final start = DateTime.utc(2026, 8, 1);
      final end = DateTime.utc(2026, 8, 10);
      expect(
        buildPartnerSeriesAnalyticsRpcParams(
          partnerId: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
          seriesId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
          preset: PartnerAnalyticsPreset.custom,
          customStart: start,
          customEnd: end,
        ),
        {
          'p_partner_id': 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
          'p_series_id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
          'p_preset': 'custom',
          'p_custom_start': start.toIso8601String(),
          'p_custom_end': end.toIso8601String(),
          'p_as_of': null,
          'p_episode_limit': 500,
          'p_episode_offset': 0,
        },
      );
    });
  });
}
