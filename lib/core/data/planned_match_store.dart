import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/match/domain/planned_match.model.dart';

abstract final class PlannedMatchStore {
  static String _key(String competitionId) => 'planned_matches_$competitionId';

  static Future<List<PlannedMatch>> get(String competitionId) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_key(competitionId));
    return encoded == null ? const [] : _decode(encoded);
  }

  static Future<void> set(
    String competitionId,
    List<PlannedMatch> matches,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    if (matches.isEmpty) {
      await prefs.remove(_key(competitionId));
      return;
    }
    await prefs.setString(
      _key(competitionId),
      jsonEncode([for (final match in matches) match.toMap()]),
    );
  }
}

List<PlannedMatch> _decode(String encoded) {
  final rows = jsonDecode(encoded);
  if (rows is! List) return const [];
  return [
    for (final row in rows)
      if (row is Map<String, dynamic>) PlannedMatch.fromMap(row),
  ];
}
