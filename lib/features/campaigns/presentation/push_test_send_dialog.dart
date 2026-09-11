import 'package:flutter/material.dart';

import '../../../l10n/admin_l10n.dart';
import '../../users/data/admin_user_wallet_repository.dart';
import '../../users/domain/admin_user_summary.dart';
import '../data/push_campaign_repository.dart';
import '../domain/admin_push_campaign.dart';
import 'campaign_test_user_picker.dart';

class PushTestSendDialog extends StatefulWidget {
  const PushTestSendDialog({
    super.key,
    required this.campaign,
    required this.repository,
    this.userRepository,
  });

  final AdminPushCampaign campaign;
  final PushCampaignRepository repository;
  final AdminUserWalletRepository? userRepository;

  @override
  State<PushTestSendDialog> createState() => _PushTestSendDialogState();
}

class _PushTestSendDialogState extends State<PushTestSendDialog> {
  static const _primaryColor = Color(0xFFE50914);

  String? _selectedUserId;
  String? _selectedLabel;
  PushUserReadiness? _matchingReadiness;
  PushUserReadiness? _overallReadiness;
  bool _loadingReadiness = false;
  bool _sending = false;
  String? _error;

  Future<void> _onUserSelected(AdminUserSummary user) async {
    setState(() {
      _selectedUserId = user.userId;
      _selectedLabel = user.resolvedDisplayName;
      _matchingReadiness = null;
      _overallReadiness = null;
      _error = null;
      _loadingReadiness = true;
    });

    try {
      final overall = await widget.repository.fetchUserReadiness(
        userId: user.userId,
      );
      var eligible = 0;
      var android = 0;
      var ios = 0;
      DateTime? latest;
      for (final locale in widget.campaign.targetLocales) {
        final slice = await widget.repository.fetchUserReadiness(
          userId: user.userId,
          locale: locale,
        );
        eligible += slice.eligibleDeviceCount;
        android += slice.androidCount;
        ios += slice.iosCount;
        final seen = slice.latestLastSeenAt;
        if (seen != null && (latest == null || seen.isAfter(latest))) {
          latest = seen;
        }
      }
      if (!mounted) return;
      setState(() {
        _overallReadiness = overall;
        _matchingReadiness = PushUserReadiness(
          userId: user.userId,
          eligibleDeviceCount: eligible,
          androidCount: android,
          iosCount: ios,
          latestLastSeenAt: latest,
        );
        _loadingReadiness = false;
      });
    } catch (error) {
      if (!mounted) return;
      debugPrint('push test readiness failed');
      setState(() {
        _loadingReadiness = false;
        _error = context.l10n.pushReadinessLoadFailed;
      });
    }
  }

  bool get _canConfirm {
    final readiness = _matchingReadiness;
    return !_sending &&
        !_loadingReadiness &&
        _selectedUserId != null &&
        readiness != null &&
        readiness.eligibleDeviceCount > 0;
  }

  Future<void> _confirm() async {
    final userId = _selectedUserId;
    final readiness = _matchingReadiness;
    if (userId == null || readiness == null || readiness.eligibleDeviceCount < 1) {
      return;
    }
    setState(() => _sending = true);
    try {
      await widget.repository.testSend(
        campaignId: widget.campaign.id,
        testUserId: userId,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      debugPrint('push test send failed');
      setState(() {
        _sending = false;
        _error = context.l10n.sendTestFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final matching = _matchingReadiness;
    final overall = _overallReadiness;
    final localeMismatch =
        overall != null &&
        overall.eligibleDeviceCount > 0 &&
        (matching == null || matching.eligibleDeviceCount == 0);

    return AlertDialog(
      backgroundColor: const Color(0xFF111111),
      title: Text(l10n.sendTest),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.sendTestHint,
                key: const Key('push-test-send-hint'),
              ),
              const SizedBox(height: 12),
              Text(l10n.sendNowHint),
              const SizedBox(height: 12),
              Text(
                widget.campaign.displayTitle,
                key: const Key('push-test-send-campaign-title'),
              ),
              Text(
                widget.campaign.targetLocales.join(', '),
                key: const Key('push-test-send-campaign-locales'),
              ),
              const SizedBox(height: 16),
              CampaignTestUserPicker(
                selectedUserId: _selectedUserId,
                selectedLabel: _selectedLabel,
                onSelected: _onUserSelected,
                onCleared: () {
                  setState(() {
                    _selectedUserId = null;
                    _selectedLabel = null;
                    _matchingReadiness = null;
                    _overallReadiness = null;
                  });
                },
                userRepository: widget.userRepository,
              ),
              if (_loadingReadiness) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
              ],
              if (matching != null) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.pushEligibleDevices(matching.eligibleDeviceCount),
                  key: const Key('push-readiness-eligible-count'),
                ),
                Text(
                  l10n.pushAndroidCount(matching.androidCount),
                  key: const Key('push-readiness-android'),
                ),
                Text(
                  l10n.pushIosCount(matching.iosCount),
                  key: const Key('push-readiness-ios'),
                ),
                if (matching.latestLastSeenAt != null)
                  Text(l10n.pushLastSeen(matching.latestLastSeenAt!.toIso8601String())),
              ],
              if (matching != null && matching.eligibleDeviceCount == 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    localeMismatch
                        ? l10n.pushLocaleMismatch
                        : l10n.pushNoEligibleDevices,
                    key: const Key('push-readiness-blocked'),
                    style: const TextStyle(color: Colors.orange),
                  ),
                ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  key: const Key('push-test-send-error'),
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('push-test-send-confirm'),
          onPressed: _canConfirm ? _confirm : null,
          style: FilledButton.styleFrom(backgroundColor: _primaryColor),
          child: Text(l10n.sendTest),
        ),
      ],
    );
  }
}
