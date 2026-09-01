import 'partner_parse_helpers.dart';

class PartnerSeriesAssignment {
  const PartnerSeriesAssignment({
    required this.id,
    required this.seriesId,
    required this.partnerId,
    required this.startsAt,
    this.endsAt,
    this.seriesTitle,
    this.partnerDisplayName,
    this.createdAt,
  });

  final String id;
  final String seriesId;
  final String partnerId;
  final DateTime startsAt;
  final DateTime? endsAt;
  final String? seriesTitle;
  final String? partnerDisplayName;
  final DateTime? createdAt;

  bool get isActive => endsAt == null;

  factory PartnerSeriesAssignment.fromMap(Map<String, dynamic> map) {
    return PartnerSeriesAssignment(
      id: _requireAssignmentId(map),
      seriesId: PartnerParseHelpers.requireUuid(
        map['series_id'],
        fieldName: 'series_id',
      ),
      partnerId: PartnerParseHelpers.requireUuid(
        map['partner_id'],
        fieldName: 'partner_id',
      ),
      startsAt: PartnerParseHelpers.requireUtcDateTime(
        map['starts_at'],
        fieldName: 'starts_at',
      ),
      endsAt: PartnerParseHelpers.optionalUtcDateTime(map['ends_at']),
      seriesTitle: PartnerParseHelpers.optionalString(map['series_title']),
      partnerDisplayName: PartnerParseHelpers.optionalString(
        map['partner_display_name'],
      ),
      createdAt: PartnerParseHelpers.optionalUtcDateTime(map['created_at']),
    );
  }

  static String _requireAssignmentId(Map<String, dynamic> map) {
    final value = map.containsKey('assignment_id')
        ? map['assignment_id']
        : map['id'];
    return PartnerParseHelpers.requireUuid(value, fieldName: 'assignment_id');
  }
}

class SetSeriesPartnerResult {
  const SetSeriesPartnerResult({
    required this.seriesId,
    required this.contentVersion,
    this.partnerId,
    this.assignmentId,
  });

  final String seriesId;
  final String? partnerId;
  final String? assignmentId;
  final int contentVersion;

  factory SetSeriesPartnerResult.fromMap(Map<String, dynamic> map) {
    return SetSeriesPartnerResult(
      seriesId: PartnerParseHelpers.requireUuid(
        map['series_id'],
        fieldName: 'series_id',
      ),
      partnerId: PartnerParseHelpers.optionalUuid(
        map['partner_id'],
        fieldName: 'partner_id',
      ),
      assignmentId: PartnerParseHelpers.optionalUuid(
        map['assignment_id'] ?? map['closed_assignment_id'],
        fieldName: 'assignment_id',
      ),
      contentVersion: PartnerParseHelpers.requireInt(
        map['content_version'],
        fieldName: 'content_version',
      ),
    );
  }
}
