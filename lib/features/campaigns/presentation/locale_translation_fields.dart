import 'package:flutter/material.dart';

import '../../../core/locale/vidxon_product_locales.dart';
import '../../../l10n/admin_l10n.dart';

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
            decoration: InputDecoration(
              labelText: context.l10n.titleForLocaleRequired(locale),
            ),
            validator: (v) => v == null || v.trim().isEmpty
                ? context.l10n.titleRequiredShort
                : null,
          ),
          if (descriptionController != null && !showBody) ...[
            const SizedBox(height: 8),
            TextFormField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: context.l10n.descriptionForLocale(locale),
              ),
              maxLines: 2,
            ),
          ],
          if (bodyController != null && showBody) ...[
            const SizedBox(height: 8),
            TextFormField(
              controller: bodyController,
              decoration: InputDecoration(
                labelText: context.l10n.messageForLocaleRequired(locale),
              ),
              maxLines: 2,
              validator: (v) => v == null || v.trim().isEmpty
                  ? context.l10n.messageRequired
                  : null,
            ),
          ],
          if (ctaController != null) ...[
            const SizedBox(height: 8),
            TextFormField(
              controller: ctaController,
              decoration: InputDecoration(
                labelText: ctaRequired
                    ? context.l10n.ctaButtonForLocaleRequired(locale)
                    : context.l10n.ctaButtonForLocale(locale),
              ),
              validator: ctaRequired
                  ? (v) => v == null || v.trim().isEmpty
                        ? context.l10n.ctaRequired
                        : null
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}
