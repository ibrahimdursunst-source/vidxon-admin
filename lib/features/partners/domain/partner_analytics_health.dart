import 'partner_parse_helpers.dart';
import 'partner_status.dart';

class PartnerAnalyticsHealth {
  const PartnerAnalyticsHealth({
    required this.status,
    required this.generatedAt,
    required this.checks,
  });

  final PartnerDataIntegrityStatus status;
  final DateTime generatedAt;
  final List<PartnerAnalyticsHealthCheck> checks;

  factory PartnerAnalyticsHealth.fromJson(Map<String, dynamic> json) {
    final checksRaw = PartnerParseHelpers.requireField(json, 'checks');
    if (checksRaw is! List) {
      throw const FormatException('checks is invalid.');
    }

    return PartnerAnalyticsHealth(
      status: PartnerDataIntegrityStatus.parse(
        PartnerParseHelpers.requireField(json, 'status'),
      ),
      generatedAt: PartnerParseHelpers.requireUtcDateTime(
        PartnerParseHelpers.requireField(json, 'generated_at'),
        fieldName: 'generated_at',
      ),
      checks: checksRaw.map((item) {
        if (item is! Map) {
          throw const FormatException('checks item is invalid.');
        }
        return PartnerAnalyticsHealthCheck.fromJson(
          Map<String, dynamic>.from(item),
        );
      }).toList(growable: false),
    );
  }
}

class PartnerAnalyticsHealthCheck {
  const PartnerAnalyticsHealthCheck({
    required this.code,
    required this.status,
    required this.message,
  });

  final String code;
  final PartnerDataIntegrityStatus status;
  final String message;

  factory PartnerAnalyticsHealthCheck.fromJson(Map<String, dynamic> json) {
    return PartnerAnalyticsHealthCheck(
      code: PartnerParseHelpers.requireString(
        PartnerParseHelpers.requireField(json, 'code'),
        fieldName: 'code',
      ),
      status: PartnerDataIntegrityStatus.parse(
        PartnerParseHelpers.requireField(json, 'status'),
      ),
      message: PartnerParseHelpers.requireString(
        PartnerParseHelpers.requireField(json, 'message'),
        fieldName: 'message',
      ),
    );
  }
}
