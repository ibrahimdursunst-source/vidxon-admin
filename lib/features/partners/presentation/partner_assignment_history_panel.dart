import 'package:flutter/material.dart';

import '../../../l10n/admin_l10n.dart';
import '../../users/domain/user_parse_helpers.dart';
import '../domain/partner_series_assignment.dart';

class PartnerAssignmentHistoryPanel extends StatelessWidget {
  const PartnerAssignmentHistoryPanel({
    required this.assignments,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.showSeriesTitle = false,
    super.key,
  });

  final List<PartnerSeriesAssignment> assignments;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final bool showSeriesTitle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF111111),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFF2A2A2A)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.assignmentHistory,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.assignmentHistoryHint,
              style: const TextStyle(color: Color(0xFF777777), fontSize: 12),
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (errorMessage != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    errorMessage!,
                    style: const TextStyle(color: Color(0xFFFFB4B4)),
                  ),
                  if (onRetry != null) ...[
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: onRetry,
                      child: Text(context.l10n.retry),
                    ),
                  ],
                ],
              )
            else if (assignments.isEmpty)
              Text(
                context.l10n.noPartnerAssignments,
                style: const TextStyle(color: Color(0xFFB3B3B3)),
              )
            else
              for (final assignment in assignments) ...[
                _AssignmentRow(
                  assignment: assignment,
                  showSeriesTitle: showSeriesTitle,
                ),
                const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }
}

class _AssignmentRow extends StatelessWidget {
  const _AssignmentRow({
    required this.assignment,
    required this.showSeriesTitle,
  });

  final PartnerSeriesAssignment assignment;
  final bool showSeriesTitle;

  @override
  Widget build(BuildContext context) {
    final name =
        assignment.partnerDisplayName ??
        (showSeriesTitle
            ? (assignment.seriesTitle ?? assignment.seriesId)
            : assignment.partnerId);
    final range =
        '${formatUserDateTime(assignment.startsAt)} → '
        '${assignment.endsAt == null ? context.l10n.ongoingAssignment : formatUserDateTime(assignment.endsAt)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: assignment.isActive
              ? const Color(0xFFE50914).withValues(alpha: 0.45)
              : const Color(0xFF2A2A2A),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  showSeriesTitle
                      ? (assignment.seriesTitle ??
                            context.l10n.destinationSeries)
                      : name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              if (assignment.isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE50914).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    context.l10n.active,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFFFB4B4),
                    ),
                  ),
                ),
            ],
          ),
          if (showSeriesTitle) ...[
            const SizedBox(height: 4),
            Text(
              assignment.partnerDisplayName ?? assignment.partnerId,
              style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 13),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            range,
            style: const TextStyle(color: Color(0xFF777777), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
