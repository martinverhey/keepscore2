import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/features/match/domain/game_type.enum.dart';
import 'package:keepscore2/features/profile/domain/head_to_head_record.model.dart';
import 'package:keepscore2/features/profile/domain/streak.model.dart';

void main() {
  test('GameType.fromWire maps each known shape and defaults to mixed', () {
    expect(GameType.fromWire('1v1'), GameType.oneVOne);
    expect(GameType.fromWire('2v2'), GameType.twoVTwo);
    expect(GameType.fromWire('3v3'), GameType.threeVThree);
    expect(GameType.fromWire('4v4'), GameType.fourVFour);
    expect(GameType.fromWire('mixed'), GameType.mixed);
    expect(GameType.fromWire('5v5'), GameType.mixed);
  });

  test('HeadToHeadRecord reads a head_to_head row', () {
    final record = HeadToHeadRecord.fromMap({
      'game_type': '2v2',
      'wins': 3,
      'losses': 1,
      'draws': 2,
    });

    expect(record.gameType, GameType.twoVTwo);
    expect(record.wins, 3);
    expect(record.draws, 2);
  });

  test('Streak reads a player_streak row', () {
    final streak = Streak.fromMap({'streak_type': 'loss', 'streak_count': 3});

    expect(streak.type, StreakType.loss);
    expect(streak.count, 3);
  });

  test('Streak.none is the zero value', () {
    const streak = Streak.none();

    expect(streak.type, StreakType.none);
    expect(streak.count, 0);
  });
}
