import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/partners/data/partner_errors.dart';
import 'package:vidxon_admin/features/partners/domain/admin_partner_summary.dart';
import 'package:vidxon_admin/features/partners/domain/partner_analytics_health.dart';
import 'package:vidxon_admin/features/partners/domain/partner_series_assignment.dart';
import 'package:vidxon_admin/features/partners/domain/partner_status.dart';
import 'package:vidxon_admin/features/partners/presentation/partners_page.dart';

import 'partner_test_helpers.dart';

void main() {
  group('Partner RPC envelope parsing', () {
    test('partner list envelope with partners=[] parses as empty success', () {
      final rows = parsePartnerRpcList(const {
        'ok': true,
        'partners': [],
      }, listKey: 'partners');

      expect(rows, isEmpty);
    });

    test('partner list envelope with one partner parses correctly', () {
      final rows = parsePartnerRpcList({
        'ok': true,
        'partners': [partnerListItemJson()],
      }, listKey: 'partners');

      final partner = AdminPartnerSummary.fromMap(rows.single);
      expect(partner.id, testPartnerId);
      expect(partner.displayName, 'Studio X');
      expect(partner.activeMemberCount, 0);
      expect(partner.activeAssignmentCount, 0);
    });

    test('active partner envelope parses correctly', () {
      final rows = parsePartnerRpcList({
        'ok': true,
        'partners': [
          {
            'partner_id': testPartnerId,
            'display_name': 'Studio X',
            'status': 'active',
          },
        ],
      }, listKey: 'partners');

      final option = AdminPartnerActiveOption.fromMap(rows.single);
      expect(option.id, testPartnerId);
      expect(option.displayName, 'Studio X');
    });

    test('assignment envelope with assignments=[] parses as empty success', () {
      final rows = parsePartnerRpcList(const {
        'ok': true,
        'assignments': [],
      }, listKey: 'assignments');

      expect(rows, isEmpty);
    });

    test('assignment envelope with one assignment parses correctly', () {
      final rows = parsePartnerRpcList({
        'ok': true,
        'assignments': [assignmentListItemJson()],
      }, listKey: 'assignments');

      final assignment = PartnerSeriesAssignment.fromMap(rows.single);
      expect(assignment.id, testAssignmentId);
      expect(assignment.partnerId, testPartnerId);
      expect(assignment.seriesId, testSeriesId);
    });

    test('missing ok fails', () {
      expect(
        () => parsePartnerRpcList(const {'partners': []}, listKey: 'partners'),
        throwsA(isA<PartnerException>()),
      );
    });

    test('ok:false fails', () {
      expect(
        () => parsePartnerRpcList(const {
          'ok': false,
          'partners': [],
        }, listKey: 'partners'),
        throwsA(isA<PartnerException>()),
      );
    });

    test('missing expected list key fails', () {
      expect(
        () => parsePartnerRpcList(const {'ok': true}, listKey: 'partners'),
        throwsA(isA<PartnerException>()),
      );
    });

    test('expected key with non-list value fails', () {
      expect(
        () => parsePartnerRpcList(const {
          'ok': true,
          'partners': 'bad',
        }, listKey: 'partners'),
        throwsA(isA<PartnerException>()),
      );
    });

    test('malformed list item fails', () {
      expect(
        () => parsePartnerRpcList(const {
          'ok': true,
          'partners': ['bad'],
        }, listKey: 'partners'),
        throwsA(isA<PartnerException>()),
      );
    });

    test('raw [] is rejected for envelope RPCs', () {
      expect(
        () => parsePartnerRpcList(const [], listKey: 'partners'),
        throwsA(isA<PartnerException>()),
      );
    });
  });

  group('PartnerAnalyticsHealth canonical parse', () {
    Map<String, dynamic> healthyPayload({
      List<Map<String, dynamic>> warnings = const [],
    }) {
      return {
        'ok': true,
        'metric_definition_version': 'qualified_view_v1',
        'data_integrity_status': 'healthy',
        'generated_at': '2026-08-25T12:00:00.000Z',
        'ready_episodes_missing_duration': 0,
        'episode_qualified_views_drift': 0,
        'series_qualified_views_drift': 0,
        'assignment_overlap_violations': 0,
        'orphan_assignments': 0,
        'warnings': warnings,
      };
    }

    test('canonical healthy health payload parses', () {
      final health = PartnerAnalyticsHealth.fromJson(healthyPayload());

      expect(health.status, PartnerDataIntegrityStatus.healthy);
      expect(health.warnings, isEmpty);
      expect(health.readyEpisodesMissingDuration, 0);
      expect(health.metricDefinitionVersion, 'qualified_view_v1');
    });

    test('health payload parses ready_episodes_missing_duration warning', () {
      final health = PartnerAnalyticsHealth.fromJson(
        healthyPayload(
          warnings: const [
            {'code': 'ready_episodes_missing_duration', 'count': 3},
          ],
        )..['data_integrity_status'] = 'warning',
      );

      expect(health.warnings, hasLength(1));
      expect(
        health.warnings.single.displayMessage(),
        contains('süre bilgisi eksik'),
      );
      expect(health.warnings.single.count, 3);
    });

    test('qualified_view_aggregate_drift parses both counters', () {
      final health = PartnerAnalyticsHealth.fromJson(
        healthyPayload(
          warnings: const [
            {
              'code': 'qualified_view_aggregate_drift',
              'episode_mismatch_count': 2,
              'series_mismatch_count': 1,
            },
          ],
        )..['data_integrity_status'] = 'warning',
      );

      final warning = health.warnings.single;
      expect(warning.episodeMismatchCount, 2);
      expect(warning.seriesMismatchCount, 1);
      expect(warning.displayMessage(), contains('bölüm 2'));
      expect(warning.displayMessage(), contains('dizi 1'));
    });

    test('unavailable health parses as unavailable', () {
      final health = PartnerAnalyticsHealth.fromJson(
        healthyPayload(
          warnings: const [
            {'code': 'assignment_overlap_detected', 'count': 1},
          ],
        )..['data_integrity_status'] = 'unavailable',
      );

      expect(health.status, PartnerDataIntegrityStatus.unavailable);
    });

    test(
      'missing required health counter fails instead of defaulting to zero',
      () {
        final payload = healthyPayload()..remove('orphan_assignments');

        expect(
          () => PartnerAnalyticsHealth.fromJson(payload),
          throwsA(isA<FormatException>()),
        );
      },
    );

    test('stale status/checks payload is rejected', () {
      expect(
        () => PartnerAnalyticsHealth.fromJson(const {
          'ok': true,
          'status': 'healthy',
          'checks': [],
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('unknown structurally valid warning code remains visible', () {
      final health = PartnerAnalyticsHealth.fromJson(
        healthyPayload(
          warnings: const [
            {'code': 'future_warning_code', 'count': 9},
          ],
        )..['data_integrity_status'] = 'warning',
      );

      expect(
        health.warnings.single.displayMessage(),
        'Bilinmeyen analitik uyarısı: future_warning_code.',
      );
    });

    test('malformed health does not create a trusted zero report', () {
      PartnerAnalyticsHealth? health;
      Object? caught;

      try {
        health = PartnerAnalyticsHealth.fromJson(
          parsePartnerRpcMap(const {'ok': true, 'warnings': []}),
        );
      } catch (error) {
        caught = error;
      }

      expect(caught, isA<FormatException>());
      expect(health, isNull);
    });
  });

  group('Partner zero-state UI', () {
    Future<void> pumpPartnersPage(
      WidgetTester tester,
      FakePartnerRepository repository,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(home: PartnersPage(repository: repository)),
      );
      await tester.pumpAndSettle();
      while (tester.takeException() != null) {}
    }

    testWidgets('zero partners renders Henüz Partner yok', (tester) async {
      await pumpPartnersPage(tester, FakePartnerRepository.empty());

      expect(find.text('Henüz Partner yok.'), findsOneWidget);
      expect(find.textContaining('Sunucu yanıtı geçersiz'), findsNothing);
    });

    testWidgets('healthy health payload does not show error banner', (
      tester,
    ) async {
      await pumpPartnersPage(
        tester,
        FakePartnerRepository.empty(
          health: PartnerAnalyticsHealth.fromJson({
            'ok': true,
            'metric_definition_version': 'qualified_view_v1',
            'data_integrity_status': 'healthy',
            'generated_at': '2026-08-25T12:00:00.000Z',
            'ready_episodes_missing_duration': 0,
            'episode_qualified_views_drift': 0,
            'series_qualified_views_drift': 0,
            'assignment_overlap_violations': 0,
            'orphan_assignments': 0,
            'warnings': [],
          }),
        ),
      );

      expect(
        find.textContaining('Analitik sağlık durumu alınamadı'),
        findsNothing,
      );
      expect(find.textContaining('Analitik Sağlık: Sağlıklı'), findsOneWidget);
    });
  });
}
