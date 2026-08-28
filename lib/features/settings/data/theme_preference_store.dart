import 'package:shared_preferences/shared_preferences.dart';

import '../domain/theme_preference.enum.dart';

abstract final class ThemePreferenceStore {
  static const _key = 'theme_preference';

  static Future<ThemePreference?> get() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    for (final preference in ThemePreference.values) {
      if (preference.name == stored) return preference;
    }
    return null;
  }

  static Future<void> set(ThemePreference preference) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, preference.name);
  }
}
