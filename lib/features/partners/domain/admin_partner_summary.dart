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
      id: _requirePartnerId(map),
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
      activeMemberCount: _requireCountField(
        map,
        primaryKey: 'active_member_count',
      ),
      activeAssignmentCount: _requireCountField(
        map,
        primaryKey: 'open_assignment_count',
        aliasKey: 'active_assignment_count',
      ),
    );
  }

  static String _requirePartnerId(Map<String, dynamic> map) {
    final value = map.containsKey('partner_id') ? map['partner_id'] : map['id'];
    return PartnerParseHelpers.requireUuid(value, fieldName: 'partner_id');
  }

  static int _requireCountField(
    Map<String, dynamic> map, {
    required String primaryKey,
    String? aliasKey,
  }) {
    if (map.containsKey(primaryKey)) {
      return PartnerParseHelpers.requireInt(
        map[primaryKey],
        fieldName: primaryKey,
      );
    }
    if (aliasKey != null && map.containsKey(aliasKey)) {
      return PartnerParseHelpers.requireInt(map[aliasKey], fieldName: aliasKey);
    }
    throw FormatException('$primaryKey is required.');
  }
}

class AdminPartnerActiveOption {
  const AdminPartnerActiveOption({required this.id, required this.displayName});

  final String id;
  final String displayName;

  factory AdminPartnerActiveOption.fromMap(Map<String, dynamic> map) {
    return AdminPartnerActiveOption(
      id: AdminPartnerSummary._requirePartnerId(map),
      displayName: PartnerParseHelpers.requireString(
        map['display_name'],
        fieldName: 'display_name',
      ),
    );
  }
}
