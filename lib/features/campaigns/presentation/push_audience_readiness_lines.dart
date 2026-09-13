import 'package:flutter/material.dart';

import '../../../l10n/admin_l10n.dart';
import '../data/push_campaign_repository.dart';

class PushAudienceReadinessLines extends StatelessWidget {
  const PushAudienceReadinessLines({
    super.key,
    required this.summary,
    required this.note,
    this.showZeroDevicesMessage = false,
  });

  final PushAudienceSummary summary;
  final String note;
  final bool showZeroDevicesMessage;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.pushEligibleUserCount(summary.eligibleUserCount),
          key: const Key('push-audience-eligible-users'),
        ),
        Text(
          l10n.pushEligibleDevices(summary.eligibleDeviceCount),
          key: const Key('push-audience-eligible-devices'),
        ),
        Text(
          l10n.pushAndroidCount(summary.androidDeviceCount),
          key: const Key('push-audience-android'),
        ),
        Text(
          l10n.pushIosCount(summary.iosDeviceCount),
          key: const Key('push-audience-ios'),
        ),
        const SizedBox(height: 8),
        Text(note),
        if (showZeroDevicesMessage && summary.eligibleDeviceCount == 0) ...[
          const SizedBox(height: 8),
          Text(
            l10n.pushNoEligibleAudience,
            key: const Key('push-audience-zero-devices'),
            style: const TextStyle(color: Color(0xFFFFB4AB)),
          ),
        ],
      ],
    );
  }
}
