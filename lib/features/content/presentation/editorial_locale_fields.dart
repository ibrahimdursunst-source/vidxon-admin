import 'package:flutter/material.dart';

import '../../../core/locale/vidxon_product_locales.dart';
import '../../../l10n/admin_l10n.dart';
import '../domain/editorial_copy.dart';

class EditorialLocaleControllers {
  EditorialLocaleControllers({String originalLocale = 'tr'})
    : originalLocale = originalLocale,
      selectedLocale = originalLocale {
    for (final locale in VidxonProductLocales.all) {
      title[locale] = TextEditingController();
      description[locale] = TextEditingController();
    }
  }

  final Map<String, TextEditingController> title = {};
  final Map<String, TextEditingController> description = {};
  String originalLocale;
  String selectedLocale;

  void apply({
    required String originalLocale,
    required String baseTitle,
    required String baseDescription,
    Map<String, EditorialCopy> translations = const {},
  }) {
    this.originalLocale = originalLocale;
    selectedLocale = originalLocale;
    for (final locale in VidxonProductLocales.all) {
      if (locale == originalLocale) {
        title[locale]!.text = baseTitle;
        description[locale]!.text = baseDescription;
      } else {
        final copy = translations[locale];
        title[locale]!.text = copy?.title ?? '';
        description[locale]!.text = copy?.description ?? '';
      }
    }
  }

  String get originalTitle => title[originalLocale]?.text.trim() ?? '';
  String get originalDescription =>
      description[originalLocale]?.text.trim() ?? '';

  bool hasContent(String locale) {
    if (locale == originalLocale) {
      return originalTitle.isNotEmpty || originalDescription.isNotEmpty;
    }
    return (title[locale]?.text.trim().isNotEmpty ?? false) ||
        (description[locale]?.text.trim().isNotEmpty ?? false);
  }

  List<Map<String, String?>> toPayload() {
    return [
      for (final locale in VidxonProductLocales.all)
        {
          'locale': locale,
          'title': title[locale]?.text,
          'description': description[locale]?.text,
        },
    ];
  }

  void dispose() {
    for (final controller in title.values) {
      controller.dispose();
    }
    for (final controller in description.values) {
      controller.dispose();
    }
  }
}

class EditorialLocaleFields extends StatelessWidget {
  const EditorialLocaleFields({
    super.key,
    required this.controllers,
    required this.enabled,
    required this.titleLabelBuilder,
    required this.descriptionLabelBuilder,
    this.showOriginalLocalePicker = true,
    this.lockOriginalLocale = false,
    this.onChanged,
  });

  final EditorialLocaleControllers controllers;
  final bool enabled;
  final String Function(BuildContext context, String locale) titleLabelBuilder;
  final String Function(BuildContext context, String locale)
  descriptionLabelBuilder;
  final bool showOriginalLocalePicker;
  final bool lockOriginalLocale;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final selected = controllers.selectedLocale;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showOriginalLocalePicker) ...[
          InputDecorator(
            decoration: InputDecoration(
              labelText: l10n.originalContentLanguage,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: controllers.originalLocale,
                isExpanded: true,
                items: [
                  for (final locale in VidxonProductLocales.all)
                    DropdownMenuItem(
                      value: locale,
                      child: Text(
                        '${VidxonProductLocales.chipLabel(locale)} · ${VidxonProductLocales.displayName(locale)}',
                      ),
                    ),
                ],
                onChanged: enabled && !lockOriginalLocale
                    ? (value) {
                        if (value == null) {
                          return;
                        }
                        controllers.originalLocale = value;
                        controllers.selectedLocale = value;
                        onChanged?.call();
                      }
                    : null,
              ),
            ),
          ),
          if (lockOriginalLocale) ...[
            const SizedBox(height: 6),
            Text(
              l10n.originalContentLanguageLocked,
              style: const TextStyle(fontSize: 12, color: Color(0xFFB3B3B3)),
            ),
          ],
          const SizedBox(height: 16),
        ],
        Text(
          l10n.translationLocales,
          style: const TextStyle(fontSize: 13, color: Color(0xFFB3B3B3)),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final locale in VidxonProductLocales.all)
              FilterChip(
                label: Text(VidxonProductLocales.chipLabel(locale)),
                selected: selected == locale,
                avatar: controllers.hasContent(locale)
                    ? const Icon(Icons.check, size: 14)
                    : null,
                onSelected: enabled
                    ? (_) {
                        controllers.selectedLocale = locale;
                        onChanged?.call();
                      }
                    : null,
                selectedColor: const Color(0xFFE50914).withValues(alpha: 0.3),
              ),
          ],
        ),
        const SizedBox(height: 16),
        FormField<String>(
          validator: (_) {
            if (controllers.originalTitle.isEmpty) {
              return l10n.titleRequired;
            }
            return null;
          },
          builder: (state) {
            if (state.errorText == null) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                state.errorText!,
                style: const TextStyle(color: Color(0xFFFFB4B4), fontSize: 12),
              ),
            );
          },
        ),
        TextFormField(
          key: ValueKey('editorial-title-$selected'),
          controller: controllers.title[selected],
          enabled: enabled,
          textDirection: selected == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
          textAlign: selected == 'ar' ? TextAlign.right : TextAlign.start,
          decoration: InputDecoration(
            labelText: titleLabelBuilder(context, selected),
          ),
          validator: selected == controllers.originalLocale
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.titleRequired;
                  }
                  return null;
                }
              : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          key: ValueKey('editorial-desc-$selected'),
          controller: controllers.description[selected],
          enabled: enabled,
          minLines: 3,
          maxLines: 6,
          textDirection: selected == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
          textAlign: selected == 'ar' ? TextAlign.right : TextAlign.start,
          decoration: InputDecoration(
            labelText: descriptionLabelBuilder(context, selected),
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }
}
