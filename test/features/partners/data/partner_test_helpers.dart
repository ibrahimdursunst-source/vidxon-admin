import 'package:vidxon_admin/features/partners/data/partner_repository.dart';
import 'package:vidxon_admin/features/partners/domain/admin_partner_summary.dart';
import 'package:vidxon_admin/features/partners/domain/partner_analytics_health.dart';
import 'package:vidxon_admin/features/partners/domain/partner_series_assignment.dart';

const testPartnerId = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
const testSeriesId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
const testAssignmentId = 'cccccccc-cccc-cccc-cccc-cccccccccccc';
const testUserId = 'dddddddd-dddd-dddd-dddd-dddddddddddd';
const testCreatedAt = '2026-08-25T10:00:00.000Z';
Map<String, dynamic> partnerListItemJson() {
  return {
    'partner_id': testPartnerId,
    'display_name': 'Studio X',
    'legal_name': null,
    'status': 'active',
    'created_at': '2026-08-25T10:00:00.000Z',
    'updated_at': '2026-08-25T10:00:00.000Z',
    'active_member_count': 0,
    'open_assignment_count': 0,
  };
}

Map<String, dynamic> partnerMemberJson() {
  return {
    'partner_id': testPartnerId,
    'user_id': testUserId,
    'status': 'active',
    'created_at': testCreatedAt,
    'updated_at': testCreatedAt,
    'ended_at': null,
    'email': 'member@test.local',
    'display_name': 'Member User',
  };
}

Map<String, dynamic> partnerDetailJson({
  List<Map<String, dynamic>>? members,
  List<Map<String, dynamic>>? assignments,
}) {
  return {
    'ok': true,
    'id': testPartnerId,
    'display_name': 'Studio X',
    'legal_name': null,
    'status': 'active',
    'created_at': testCreatedAt,
    'updated_at': testCreatedAt,
    'created_by': null,
    'members': members ?? const [],
    'assignments': assignments ?? const [],
  };
}

Map<String, dynamic> partnerAddMemberWriteAckJson() {
  return {
    'ok': true,
    'member_id': 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee',
    'partner_id': testPartnerId,
    'user_id': testUserId,
    'status': 'active',
  };
}
Map<String, dynamic> assignmentListItemJson() {
  return {
    'assignment_id': testAssignmentId,
    'partner_id': testPartnerId,
    'partner_display_name': 'Studio X',
    'series_id': testSeriesId,
    'series_title': 'Test Dizi',
    'starts_at': '2026-08-25T10:00:00.000Z',
    'ends_at': null,
    'created_at': '2026-08-25T10:00:00.000Z',
    'created_by': null,
  };
}

class FakePartnerRepository extends PartnerRepository {
  FakePartnerRepository({
    List<AdminPartnerSummary>? partners,
    this._health,
    List<PartnerSeriesAssignment>? assignments,
  })  : _partners = partners ?? const [],
        _assignments = assignments ?? const [],
        super(client: null);

  FakePartnerRepository.empty({PartnerAnalyticsHealth? health})
    : this(
        partners: const [],
        health: health ?? _defaultHealthyHealth(),
        assignments: const [],
      );

  static PartnerAnalyticsHealth _defaultHealthyHealth() {
    return PartnerAnalyticsHealth.fromJson({
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
    });
  }

  final List<AdminPartnerSummary> _partners;
  final PartnerAnalyticsHealth? _health;
  final List<PartnerSeriesAssignment> _assignments;

  @override
  Future<List<AdminPartnerSummary>> listPartners() async {
    return _partners;
  }

  @override
  Future<PartnerAnalyticsHealth> fetchAnalyticsHealth() async {
    final health = _health;
    if (health == null) {
      throw StateError('health not configured');
    }
    return health;
  }

  @override
  Future<List<PartnerSeriesAssignment>> fetchAssignmentHistory(
    String seriesId,
  ) async {
    return _assignments;
  }
}
