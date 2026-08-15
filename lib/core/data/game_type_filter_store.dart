import 'package:shared_preferences/shared_preferences.dart';

import '../../features/match/domain/game_type.enum.dart';

abstract final class GameTypeFilterStore {
  static const _key = 'selected_game_type';

  static Future<GameType?> get() async {
    final prefs = await SharedPreferences.getInstance();
    final wireValue = prefs.getString(_key);
    return wireValue == null ? null : GameType.fromWire(wireValue);
  }

  static Future<void> set(GameType? gameType) async {
    final prefs = await SharedPreferences.getInstance();
    if (gameType == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, gameType.wireValue);
    }
  }
}
