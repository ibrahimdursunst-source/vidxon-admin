import 'admin_partner_member.dart';
import 'admin_partner_summary.dart';
import 'partner_parse_helpers.dart';
import 'partner_series_assignment.dart';
import 'partner_status.dart';

class AdminPartnerDetail {
  const AdminPartnerDetail({
    required this.id,
    required this.displayName,
    required this.status,
    required this.createdAt,
    required this.members,
    required this.assignments,
    this.legalName,
    this.updatedAt,
    this.createdBy,
  });

  final String id;
  final String displayName;
  final String? legalName;
  final PartnerStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final List<AdminPartnerMember> members;
  final List<PartnerSeriesAssignment> assignments;

  AdminPartnerSummary toSummary() {
    return AdminPartnerSummary(
      id: id,
      displayName: displayName,
      legalName: legalName,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      activeMemberCount: members
          .where((m) => m.status == PartnerMemberStatus.active)
          .length,
      activeAssignmentCount: assignments.where((a) => a.isActive).length,
    );
  }

  factory AdminPartnerDetail.fromMap(Map<String, dynamic> map) {
    final membersRaw = PartnerParseHelpers.requireField(map, 'members');
    final assignmentsRaw = PartnerParseHelpers.requireField(map, 'assignments');

    return AdminPartnerDetail(
      id: PartnerParseHelpers.requireUuid(map['id'], fieldName: 'id'),
      displayName: PartnerParseHelpers.requireString(
        map['display_name'],
        fieldName: 'display_name',
      ),
      legalName: PartnerParseHelpers.optionalString(map['legal_name']),
      status: PartnerStatus.parse(map['status']),
      createdAt: PartnerParseHelpers.requireUtcDateTime(
        map['created_at'],
        fieldName: 'created_at',
      ),
      updatedAt: PartnerParseHelpers.optionalUtcDateTime(map['updated_at']),
      createdBy: PartnerParseHelpers.optionalUuid(
        map['created_by'],
        fieldName: 'created_by',
      ),
      members: _parseMembers(membersRaw),
      assignments: _parseAssignments(assignmentsRaw),
    );
  }

  static List<AdminPartnerMember> _parseMembers(dynamic raw) {
    if (raw is! List) {
      throw const FormatException('members is invalid.');
    }
    return raw
        .map((item) {
          if (item is! Map) {
            throw const FormatException('members item is invalid.');
          }
          return AdminPartnerMember.fromMap(Map<String, dynamic>.from(item));
        })
        .toList(growable: false);
  }

  static List<PartnerSeriesAssignment> _parseAssignments(dynamic raw) {
    if (raw is! List) {
      throw const FormatException('assignments is invalid.');
    }
    return raw
        .map((item) {
          if (item is! Map) {
            throw const FormatException('assignments item is invalid.');
          }
          return PartnerSeriesAssignment.fromMap(
            Map<String, dynamic>.from(item),
          );
        })
        .toList(growable: false);
  }
}
