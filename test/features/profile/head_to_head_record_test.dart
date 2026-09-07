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
      'wins': 3,
      'losses': 1,
      'draws': 2,
      'biggest_win_score': 21,
      'biggest_win_opponent_score': 3,
      'biggest_shutout_score': 15,
      'shutout_wins': 3,
    });

    expect(record.wins, 3);
    expect(record.losses, 1);
    expect(record.draws, 2);
    expect(record.biggestWin, const BiggestWin(score: 21, opponentScore: 3));
    expect(
      record.biggestShutout,
      const BiggestWin(score: 15, opponentScore: 0),
    );
    expect(record.shutoutWins, 3);
  });

  test('HeadToHeadRecord has no biggest win until the player has won one', () {
    final record = HeadToHeadRecord.fromMap({
      'wins': 0,
      'losses': 2,
      'draws': 0,
      'biggest_win_score': null,
      'biggest_win_opponent_score': null,
      'biggest_shutout_score': null,
      'shutout_wins': 0,
    });

    expect(record.biggestWin, isNull);
    expect(record.biggestShutout, isNull);
    expect(record.shutoutWins, 0);
  });

  test('HeadToHeadRecord keeps a biggest win that was not a shutout', () {
    final record = HeadToHeadRecord.fromMap({
      'wins': 2,
      'losses': 0,
      'draws': 0,
      'biggest_win_score': 21,
      'biggest_win_opponent_score': 3,
      'biggest_shutout_score': null,
      'shutout_wins': 0,
    });

    expect(record.biggestWin, const BiggestWin(score: 21, opponentScore: 3));
    expect(record.biggestShutout, isNull);
    expect(record.shutoutWins, 0);
  });

  test('HeadToHeadRecord.zero is the zero value', () {
    const record = HeadToHeadRecord.zero();

    expect(record.wins, 0);
    expect(record.losses, 0);
    expect(record.draws, 0);
    expect(record.biggestWin, isNull);
    expect(record.biggestShutout, isNull);
    expect(record.shutoutWins, 0);
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
