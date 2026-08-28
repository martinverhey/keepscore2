import 'package:shared_preferences/shared_preferences.dart';

import '../domain/language_preference.enum.dart';

abstract final class LanguagePreferenceStore {
  static const _key = 'language_preference';

  static Future<LanguagePreference> get() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    return LanguagePreference.values.firstWhere(
      (preference) => preference.name == stored,
      orElse: () => LanguagePreference.system,
    );
  }

  static Future<void> set(LanguagePreference preference) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, preference.name);
  }
}
