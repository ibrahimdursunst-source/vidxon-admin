import 'partner_parse_helpers.dart';
import 'partner_status.dart';

class AdminPartnerSummary {
  const AdminPartnerSummary({
    required this.id,
    required this.displayName,
    required this.status,
    required this.createdAt,
    this.legalName,
    this.updatedAt,
    this.activeMemberCount = 0,
    this.activeAssignmentCount = 0,
  });

  final String id;
  final String displayName;
  final String? legalName;
  final PartnerStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int activeMemberCount;
  final int activeAssignmentCount;

  factory AdminPartnerSummary.fromMap(Map<String, dynamic> map) {
    return AdminPartnerSummary(
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
      activeMemberCount: map.containsKey('active_member_count')
          ? PartnerParseHelpers.requireInt(
              map['active_member_count'],
              fieldName: 'active_member_count',
            )
          : 0,
      activeAssignmentCount: map.containsKey('active_assignment_count')
          ? PartnerParseHelpers.requireInt(
              map['active_assignment_count'],
              fieldName: 'active_assignment_count',
            )
          : 0,
    );
  }
}

class AdminPartnerActiveOption {
  const AdminPartnerActiveOption({
    required this.id,
    required this.displayName,
  });

  final String id;
  final String displayName;

  factory AdminPartnerActiveOption.fromMap(Map<String, dynamic> map) {
    return AdminPartnerActiveOption(
      id: PartnerParseHelpers.requireUuid(map['id'], fieldName: 'id'),
      displayName: PartnerParseHelpers.requireString(
        map['display_name'],
        fieldName: 'display_name',
      ),
    );
  }
}
