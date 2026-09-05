import 'package:flutter/material.dart';

import '../application/admin_locale_controller.dart';
import '../domain/admin_ui_locales.dart';

class AdminLanguageSelector extends StatelessWidget {
  const AdminLanguageSelector({required this.controller, super.key});

  final AdminLocaleController controller;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        key: const Key('admin-ui-language-selector'),
        value: controller.languageCode,
        dropdownColor: const Color(0xFF181818),
        style: const TextStyle(color: Color(0xFFEDEDED), fontSize: 13),
        onChanged: (code) {
          if (code != null) {
            controller.setLanguageCode(code);
          }
        },
        items: [
          for (final code in AdminUiLocales.supportedCodes)
            DropdownMenuItem<String>(
              value: code,
              child: Text(AdminUiLocales.displayNames[code]!),
            ),
        ],
      ),
    );
  }
}
