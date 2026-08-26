import 'partner_parse_helpers.dart';
import 'partner_status.dart';

class AdminPartnerMember {
  const AdminPartnerMember({
    required this.partnerId,
    required this.userId,
    required this.status,
    required this.createdAt,
    this.email,
    this.displayName,
    this.endedAt,
    this.updatedAt,
  });

  final String partnerId;
  final String userId;
  final PartnerMemberStatus status;
  final DateTime createdAt;
  final String? email;
  final String? displayName;
  final DateTime? endedAt;
  final DateTime? updatedAt;

  factory AdminPartnerMember.fromMap(Map<String, dynamic> map) {
    return AdminPartnerMember(
      partnerId: PartnerParseHelpers.requireUuid(
        map['partner_id'],
        fieldName: 'partner_id',
      ),
      userId: PartnerParseHelpers.requireUuid(
        map['user_id'],
        fieldName: 'user_id',
      ),
      status: PartnerMemberStatus.parse(map['status']),
      createdAt: PartnerParseHelpers.requireUtcDateTime(
        map['created_at'],
        fieldName: 'created_at',
      ),
      email: PartnerParseHelpers.optionalString(map['email']),
      displayName: PartnerParseHelpers.optionalString(map['display_name']),
      endedAt: PartnerParseHelpers.optionalUtcDateTime(map['ended_at']),
      updatedAt: PartnerParseHelpers.optionalUtcDateTime(map['updated_at']),
    );
  }
}

class PartnerLookupUser {
  const PartnerLookupUser({
    required this.userId,
    required this.email,
    this.displayName,
  });

  final String userId;
  final String email;
  final String? displayName;

  factory PartnerLookupUser.fromMap(Map<String, dynamic> map) {
    return PartnerLookupUser(
      userId: PartnerParseHelpers.requireUuid(
        map['user_id'],
        fieldName: 'user_id',
      ),
      email: PartnerParseHelpers.requireString(map['email'], fieldName: 'email'),
      displayName: PartnerParseHelpers.optionalString(map['display_name']),
    );
  }
}
