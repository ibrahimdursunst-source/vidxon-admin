import 'package:flutter/material.dart';

import '../../../l10n/admin_l10n.dart';
import '../domain/content_rating_catalog.dart';

class ContentRatingEditor extends StatelessWidget {
  const ContentRatingEditor({
    required this.ageRating,
    required this.descriptors,
    required this.onAgeChanged,
    required this.onDescriptorsChanged,
    this.enabled = true,
    this.showSectionTitle = true,
    this.includeAge = true,
    this.includeDescriptors = true,
    super.key,
  });

  final int? ageRating;
  final List<String> descriptors;
  final ValueChanged<int?> onAgeChanged;
  final ValueChanged<List<String>> onDescriptorsChanged;
  final bool enabled;
  final bool showSectionTitle;
  final bool includeAge;
  final bool includeDescriptors;

  void _toggleDescriptor(String id, bool selected) {
    final next = Set<String>.from(descriptors);
    if (selected) {
      next.add(id);
      if (id == 'strong_violence') {
        next.remove('violence');
      } else if (id == 'violence') {
        next.remove('strong_violence');
      }
    } else {
      next.remove(id);
    }
    onDescriptorsChanged(ContentRatingCatalog.normalizeDescriptors(next));
  }

  @override
  Widget build(BuildContext context) {
    final selected = ContentRatingCatalog.normalizeDescriptors(descriptors);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showSectionTitle) ...[
          Text(
            context.l10n.contentRating,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          context.l10n.contentRatingDisclaimer,
          style: const TextStyle(color: Color(0xFF777777), fontSize: 12),
        ),
        if (includeAge) ...[
          const SizedBox(height: 16),
          InputDecorator(
            decoration: InputDecoration(labelText: context.l10n.ageRating),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                value: ageRating,
                isExpanded: true,
                items: [
                  for (final age in ContentRatingCatalog.ages)
                    DropdownMenuItem(
                      value: age,
                      child: Text(adminAgeRatingLabel(context.l10n, age)),
                    ),
                ],
                onChanged: enabled ? onAgeChanged : null,
              ),
            ),
          ),
        ],
        if (includeDescriptors) ...[
          const SizedBox(height: 16),
          Text(
            context.l10n.contentDescriptors,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final id in ContentRatingCatalog.descriptorIds)
                FilterChip(
                  label: Text(adminDescriptorLabel(context.l10n, id)),
                  selected: selected.contains(id),
                  onSelected: enabled
                      ? (value) => _toggleDescriptor(id, value)
                      : null,
                ),
            ],
          ),
        ],
      ],
    );
  }
}
