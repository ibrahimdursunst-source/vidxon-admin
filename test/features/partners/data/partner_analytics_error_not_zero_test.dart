import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/partners/data/partner_errors.dart';
import 'package:vidxon_admin/features/partners/data/partner_repository.dart';
import 'package:vidxon_admin/features/partners/domain/partner_analytics_report.dart';
import 'package:vidxon_admin/features/partners/domain/partner_status.dart';

/// Demonstrates repository analytics contract: parse/load failures throw
/// [PartnerException] and never yield a synthetic zero report.
class _ThrowingPartnerRepository extends PartnerRepository {
  _ThrowingPartnerRepository() : super(client: null);

  @override
  Future<PartnerAnalyticsReport> fetchSeriesAnalytics({
    required String partnerId,
    required String seriesId,
    required PartnerAnalyticsPreset preset,
    DateTime? customStart,
    DateTime? customEnd,
    DateTime? asOf,
    int episodeLimit = 500,
    int episodeOffset = 0,
  }) async {
    // Simulate malformed RPC payload that fails strict parse.
    try {
      return PartnerAnalyticsReport.fromJson(const {
        'qualified_views': 0,
        // missing remaining required fields on purpose
      });
    } on FormatException catch (error) {
      throw PartnerErrorMapper.parseFailure(error.message);
    }
  }
}

void main() {
  test('analytics fetch failure does not become a zero report', () async {
    final repository = _ThrowingPartnerRepository();

    PartnerAnalyticsReport? report;
    Object? caught;

    try {
      report = await repository.fetchSeriesAnalytics(
        partnerId: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
        seriesId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        preset: PartnerAnalyticsPreset.total,
      );
    } catch (error) {
      caught = error;
    }

    expect(caught, isA<PartnerException>());
    expect((caught! as PartnerException).kind, PartnerFailureKind.parseError);
    expect(report, isNull);
    expect(report?.qualifiedViews, isNull);
    expect(report?.uniqueViewers, isNull);
  });

  test('successful zero report remains distinguishable from failure', () {
    final report = PartnerAnalyticsReport.fromJson({
      'qualified_views': 0,
      'unique_viewers': 0,
      'validated_watch_seconds': 0,
      'qualified_sessions': 0,
      'completed_sessions': 0,
      'completion_rate': null,
      'report_start': '2026-08-01T00:00:00.000Z',
      'report_end': '2026-08-08T00:00:00.000Z',
      'as_of': '2026-08-08T12:00:00.000Z',
      'generated_at': '2026-08-08T12:00:01.000Z',
      'metric_version': 'qualified_view_v1',
      'reporting_timezone': 'UTC',
      'episodes': const [],
    });

    expect(report.qualifiedViews, 0);
    expect(report.completionRate, isNull);
  });
}
