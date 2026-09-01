import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/partners/data/partner_errors.dart';
import 'package:vidxon_admin/features/partners/data/partner_repository.dart';
import 'package:vidxon_admin/features/partners/domain/partner_analytics_report.dart';
import 'package:vidxon_admin/features/partners/domain/partner_status.dart';
import 'package:vidxon_admin/features/partners/presentation/partner_analytics_panel.dart';

class _AnalyticsPanelRepository extends PartnerRepository {
  _AnalyticsPanelRepository() : super(client: null);

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
    if (preset == PartnerAnalyticsPreset.total) {
      return PartnerAnalyticsReport.fromJson({
        'preset': 'total',
        'qualified_views': 5,
        'unique_viewers': 2,
        'validated_watch_seconds': 40,
        'qualified_sessions': 3,
        'completed_sessions': 1,
        'completion_rate': 0.3,
        'resolved_start': null,
        'resolved_end': 'infinity',
        'as_of': '2026-08-08T12:00:00.000Z',
        'generated_at': '2026-08-08T12:00:01.000Z',
        'metric_definition_version': 'qualified_view_v1',
        'reporting_timezone': 'UTC',
        'data_integrity_status': 'healthy',
        'episodes': const [],
      });
    }

    return PartnerAnalyticsReport.fromJson({
      'preset': preset.value,
      'qualified_views': 5,
      'unique_viewers': 2,
      'validated_watch_seconds': 40,
      'qualified_sessions': 3,
      'completed_sessions': 1,
      'completion_rate': 0.3,
      'resolved_start': '2026-08-01T00:00:00.000Z',
      'resolved_end': '2026-08-08T00:00:00.000Z',
      'as_of': '2026-08-08T12:00:00.000Z',
      'generated_at': '2026-08-08T12:00:01.000Z',
      'metric_definition_version': 'qualified_view_v1',
      'reporting_timezone': 'UTC',
      'data_integrity_status': 'healthy',
      'episodes': const [],
    });
  }
}

void main() {
  testWidgets('Total chip remains visible and default stays last 7 days', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PartnerAnalyticsPanel(
            partnerId: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
            seriesId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
            repository: _AnalyticsPanelRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Toplam'), findsOneWidget);
    expect(find.text('Son 7 Gün'), findsOneWidget);
    expect(find.textContaining('Rapor kullanılamıyor'), findsNothing);
    expect(find.textContaining('Dönem:'), findsOneWidget);
    expect(find.textContaining('Toplam · as_of'), findsNothing);

    await tester.tap(find.text('Toplam'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Toplam · as_of'), findsOneWidget);
    expect(find.textContaining('1970'), findsNothing);
    expect(find.text('5'), findsWidgets);
  });

  testWidgets('parse failure stays unavailable and is not a fake zero', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PartnerAnalyticsPanel(
            partnerId: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
            seriesId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
            repository: _ThrowingAnalyticsRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rapor kullanılamıyor'), findsOneWidget);
    expect(
      find.text('Hata durumu sıfır aktivite olarak gösterilmez.'),
      findsOneWidget,
    );
  });
}

class _ThrowingAnalyticsRepository extends PartnerRepository {
  _ThrowingAnalyticsRepository() : super(client: null);

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
    try {
      return PartnerAnalyticsReport.fromJson(const {'ok': true});
    } on FormatException catch (error) {
      throw PartnerErrorMapper.parseFailure(error.message);
    }
  }
}
