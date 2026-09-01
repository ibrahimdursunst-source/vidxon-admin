import 'dart:io';

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
      expect(
        PartnerMetricCopy.formatCompletionRate(report.completionRate),
        '—',
      );
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

  group('TOTAL / lifetime period contract', () {
    const asOf = '2026-08-08T12:00:00.000Z';
    final asOfUtc = DateTime.parse(asOf).toUtc();
    final epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

    Map<String, dynamic> lifetimeJson({
      dynamic resolvedStart,
      dynamic resolvedEnd,
      int qualifiedViews = 42,
      int uniqueViewers = 7,
      int validatedWatchSeconds = 900,
    }) {
      return {
        'ok': true,
        'preset': 'total',
        'qualified_views': qualifiedViews,
        'unique_viewers': uniqueViewers,
        'validated_watch_seconds': validatedWatchSeconds,
        'qualified_sessions': 8,
        'completed_sessions': 4,
        'completion_rate': 0.5,
        'resolved_start': resolvedStart,
        'resolved_end': resolvedEnd,
        'as_of': asOf,
        'generated_at': '2026-08-08T12:00:01.000Z',
        'metric_definition_version': 'qualified_view_v1',
        'reporting_timezone': 'UTC',
        'data_integrity_status': 'healthy',
        'episodes': const [],
      };
    }

    test('1. total + resolved_start null parses as unbounded', () {
      final report = PartnerAnalyticsReport.fromJson(lifetimeJson());
      expect(report.isLifetime, isTrue);
      expect(report.reportStart, isNull);
      expect(report.preset, 'total');
    });

    test('2. total + resolved_start "-infinity" parses as unbounded', () {
      final report = PartnerAnalyticsReport.fromJson(
        lifetimeJson(resolvedStart: '-infinity'),
      );
      expect(report.reportStart, isNull);
    });

    test('3. total + resolved_end null uses asOf as display end', () {
      final report = PartnerAnalyticsReport.fromJson(lifetimeJson());
      expect(report.reportEnd.toUtc(), asOfUtc);
      expect(report.asOf.toUtc(), asOfUtc);
    });

    test('4. total + resolved_end "infinity" uses asOf as display end', () {
      final report = PartnerAnalyticsReport.fromJson(
        lifetimeJson(resolvedEnd: 'infinity'),
      );
      expect(report.reportEnd.toUtc(), asOfUtc);
    });

    test('5. total does not invent epoch as start', () {
      final report = PartnerAnalyticsReport.fromJson(lifetimeJson());
      expect(report.reportStart, isNull);
      expect(report.reportStart, isNot(epoch));
      expect(report.asOf.toUtc(), isNot(epoch));
    });

    test('6. total does not substitute DateTime.now()', () {
      final before = DateTime.now().toUtc();
      final report = PartnerAnalyticsReport.fromJson(lifetimeJson());
      final after = DateTime.now().toUtc();
      expect(report.asOf.toUtc(), asOfUtc);
      expect(report.reportEnd.toUtc(), asOfUtc);
      expect(
        report.asOf.toUtc().isAfter(before) &&
            report.asOf.toUtc().isBefore(after),
        isFalse,
      );
    });

    test('7. total metrics are preserved unchanged', () {
      final report = PartnerAnalyticsReport.fromJson(
        lifetimeJson(
          qualifiedViews: 42,
          uniqueViewers: 7,
          validatedWatchSeconds: 900,
        ),
      );
      expect(report.qualifiedViews, 42);
      expect(report.uniqueViewers, 7);
      expect(report.validatedWatchSeconds, 900);
      expect(report.qualifiedSessions, 8);
      expect(report.completedSessions, 4);
    });

    test('8. last_7_days + null start throws', () {
      final json = validAnalyticsJson()..['resolved_start'] = null;
      json.remove('report_start');
      expect(
        () => PartnerAnalyticsReport.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('9. bounded + "-infinity" start throws', () {
      final json = validAnalyticsJson()..['resolved_start'] = '-infinity';
      json.remove('report_start');
      expect(
        () => PartnerAnalyticsReport.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('10. bounded null/invalid end throws', () {
      final json = validAnalyticsJson()..['resolved_end'] = null;
      json.remove('report_end');
      expect(
        () => PartnerAnalyticsReport.fromJson(json),
        throwsA(isA<FormatException>()),
      );
      final invalid = validAnalyticsJson()..['resolved_end'] = 'infinity';
      invalid.remove('report_end');
      expect(
        () => PartnerAnalyticsReport.fromJson(invalid),
        throwsA(isA<FormatException>()),
      );
    });

    test('11. bounded start >= end throws', () {
      final json = validAnalyticsJson()
        ..['report_start'] = '2026-08-08T00:00:00.000Z'
        ..['report_end'] = '2026-08-08T00:00:00.000Z';
      expect(
        () => PartnerAnalyticsReport.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('12. custom missing either bound throws', () {
      final missingStart = validAnalyticsJson()..['preset'] = 'custom';
      missingStart.remove('report_start');
      missingStart.remove('resolved_start');
      expect(
        () => PartnerAnalyticsReport.fromJson(missingStart),
        throwsA(isA<FormatException>()),
      );

      final missingEnd = validAnalyticsJson()..['preset'] = 'custom';
      missingEnd.remove('report_end');
      missingEnd.remove('resolved_end');
      expect(
        () => PartnerAnalyticsReport.fromJson(missingEnd),
        throwsA(isA<FormatException>()),
      );
    });

    test('13. malformed total sentinel "abc" throws', () {
      expect(
        () => PartnerAnalyticsReport.fromJson(
          lifetimeJson(resolvedStart: 'abc'),
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('lifetime caption does not invent a start date', () {
      final report = PartnerAnalyticsReport.fromJson(lifetimeJson());
      final caption = report.periodCaption(
        formattedAsOf: '08.08.2026 15:00',
      );
      expect(caption, startsWith('Toplam · as_of '));
      expect(caption.contains('1970'), isFalse);
      expect(caption.contains('01.01.1970'), isFalse);
      expect(caption.contains('→'), isFalse);
    });

    test('15. Total chip label remains in the analytics panel', () {
      final source = File(
        'lib/features/partners/presentation/partner_analytics_panel.dart',
      ).readAsStringSync();
      expect(source.contains('for (final preset in PartnerAnalyticsPreset.values)'), isTrue);
      expect(
        File('lib/features/partners/domain/partner_status.dart').readAsStringSync(),
        contains("total('total', 'Toplam')"),
      );
    });

    test('16. Admin default preset remains last 7 days', () {
      final source = File(
        'lib/features/partners/presentation/partner_analytics_panel.dart',
      ).readAsStringSync();
      expect(
        source.contains(
          'PartnerAnalyticsPreset _preset = PartnerAnalyticsPreset.last7Days',
        ),
        isTrue,
      );
    });

    test('fromJson lifetime path does not call DateTime.now', () {
      final source = File(
        'lib/features/partners/domain/partner_analytics_report.dart',
      ).readAsStringSync();
      expect(source.contains('DateTime.now('), isFalse);
    });
  });

  group('Partner RPC params', () {
    test('create uses p_display_name and p_legal_name', () {
      expect(
        buildPartnerCreateRpcParams(
          displayName: ' Studio X ',
          legalName: ' Studio X LLC ',
        ),
        {'p_display_name': 'Studio X', 'p_legal_name': 'Studio X LLC'},
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
