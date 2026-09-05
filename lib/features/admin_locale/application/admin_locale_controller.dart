import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/admin_ui_locales.dart';

/// Local-only Admin UI locale preference. No network or Supabase access.
class AdminLocaleController extends ChangeNotifier {
  AdminLocaleController({this._preferences});

  static const storageKey = 'vidxon_admin_ui_locale';

  SharedPreferences? _preferences;
  Locale _locale = const Locale(AdminUiLocales.defaultCode);

  Locale get locale => _locale;

  String get languageCode => _locale.languageCode;

  Future<void> load() async {
    _preferences ??= await SharedPreferences.getInstance();
    _locale = AdminUiLocales.resolve(_preferences!.getString(storageKey));
    notifyListeners();
  }

  Future<void> setLanguageCode(String code) async {
    final next = AdminUiLocales.resolve(code);
    if (next.languageCode == _locale.languageCode) {
      return;
    }
    _locale = next;
    notifyListeners();
    _preferences ??= await SharedPreferences.getInstance();
    await _preferences!.setString(storageKey, next.languageCode);
  }
}
