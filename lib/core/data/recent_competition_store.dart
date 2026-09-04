import 'package:shared_preferences/shared_preferences.dart';

abstract final class RecentCompetitionStore {
  static const _key = 'recent_competition_id';

  static Future<String?> get() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  static Future<void> set(String competitionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, competitionId);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static Future<void> clearIfRecent(String competitionId) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_key) != competitionId) return;
    await prefs.remove(_key);
  }
}
