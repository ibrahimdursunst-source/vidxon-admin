import 'package:flutter/material.dart';

/// Admin interface languages only. Independent from [VidxonProductLocales].
abstract final class AdminUiLocales {
  static const tr = 'tr';
  static const en = 'en';
  static const defaultCode = tr;

  static const supportedCodes = <String>[tr, en];

  static const supportedLocales = <Locale>[Locale(tr), Locale(en)];

  static const displayNames = <String, String>{tr: 'Türkçe', en: 'English'};

  static Locale resolve(String? raw) {
    final code = raw?.trim().toLowerCase();
    if (code == en) {
      return const Locale(en);
    }
    return const Locale(tr);
  }

  static bool isSupported(String? raw) =>
      raw != null && supportedCodes.contains(raw.trim().toLowerCase());
}
