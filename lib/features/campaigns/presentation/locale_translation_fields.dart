import 'package:flutter/material.dart';

import '../../../core/locale/vidxon_product_locales.dart';

/// Reusable per-locale translation fields for campaign forms.
class LocaleTranslationFields extends StatelessWidget {
  const LocaleTranslationFields({
    super.key,
    required this.locale,
    required this.titleController,
    this.descriptionController,
    this.ctaController,
    this.bodyController,
    this.ctaRequired = false,
    this.showBody = false,
  });

  final String locale;
  final TextEditingController titleController;
  final TextEditingController? descriptionController;
  final TextEditingController? ctaController;
  final TextEditingController? bodyController;
  final bool ctaRequired;

  /// If true, shows "Body" instead of "Description" (for push).
  final bool showBody;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              VidxonProductLocales.displayName(locale),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: titleController,
            decoration: InputDecoration(labelText: 'Başlık ($locale) *'),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Başlık zorunlu' : null,
          ),
          if (descriptionController != null && !showBody) ...[
            const SizedBox(height: 8),
            TextFormField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: 'Açıklama ($locale)'),
              maxLines: 2,
            ),
          ],
          if (bodyController != null && showBody) ...[
            const SizedBox(height: 8),
            TextFormField(
              controller: bodyController,
              decoration: InputDecoration(labelText: 'Mesaj ($locale) *'),
              maxLines: 2,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Mesaj zorunlu' : null,
            ),
          ],
          if (ctaController != null) ...[
            const SizedBox(height: 8),
            TextFormField(
              controller: ctaController,
              decoration: InputDecoration(
                labelText: 'CTA Butonu ($locale)${ctaRequired ? ' *' : ''}',
              ),
              validator: ctaRequired
                  ? (v) => v == null || v.trim().isEmpty ? 'CTA zorunlu' : null
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}
