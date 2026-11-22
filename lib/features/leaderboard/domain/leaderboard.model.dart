import 'package:equatable/equatable.dart';

import '../../profile/domain/streak_type.enum.dart';
import 'medal.enum.dart';
import 'season_leaderboard.model.dart';

export '../../profile/domain/streak_type.enum.dart';
export 'medal.enum.dart';

class Leaderboard extends Equatable {
  const Leaderboard({
    required this.seasonId,
    required this.competitionId,
    required this.playerId,
    required this.displayName,
    required this.isClaimed,
    required this.isOwner,
    required this.rating,
    required this.played,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.rank,
    this.streakType = StreakType.none,
    this.streakCount = 0,
    this.todayDelta = 0,
    this.medal,
  });

  factory Leaderboard.fromMap(Map<String, dynamic> map) => Leaderboard(
    seasonId: map['season_id'] as String,
    competitionId: map['competition_id'] as String,
    playerId: map['player_id'] as String,
    displayName: map['display_name'] as String,
    isClaimed: map['is_claimed'] as bool? ?? false,
    isOwner: map['is_owner'] as bool? ?? false,
    rating: _toDouble(map['rating']),
    played: (map['played'] as num?)?.toInt() ?? 0,
    wins: (map['wins'] as num?)?.toInt() ?? 0,
    losses: (map['losses'] as num?)?.toInt() ?? 0,
    draws: (map['draws'] as num?)?.toInt() ?? 0,
    rank: (map['rank'] as num?)?.toInt() ?? 0,
    streakType: StreakType.fromWire(map['streak_type'] as String? ?? 'none'),
    streakCount: (map['streak_count'] as num?)?.toInt() ?? 0,
    todayDelta: _toDouble(map['today_delta']),
  );

  factory Leaderboard.fromSeasonLeaderboard(SeasonLeaderboard leaderboard) =>
      Leaderboard(
        seasonId: leaderboard.seasonId,
        competitionId: leaderboard.competitionId,
        playerId: leaderboard.playerId,
        displayName: leaderboard.displayName,
        isClaimed: leaderboard.isClaimed,
        isOwner: false,
        rating: leaderboard.rating,
        played: leaderboard.played,
        wins: leaderboard.wins,
        losses: leaderboard.losses,
        draws: leaderboard.draws,
        rank: leaderboard.rank,
        medal: leaderboard.medal,
      );

  factory Leaderboard.forPlayer(
    Map<String, dynamic> map, {
    required String competitionId,
  }) {
    final competition = map['competitions'] as Map<String, dynamic>;
    return Leaderboard(
      seasonId: null,
      competitionId: competitionId,
      playerId: map['id'] as String,
      displayName: map['display_name'] as String,
      isClaimed: map['user_id'] != null,
      isOwner:
          map['user_id'] != null && map['user_id'] == competition['owner_id'],
      rating: _toDouble(competition['starting_rating']),
      played: 0,
      wins: 0,
      losses: 0,
      draws: 0,
      rank: 1,
    );
  }

  final String? seasonId;
  final String competitionId;
  final String playerId;
  final String displayName;
  final bool isClaimed;
  final bool isOwner;
  final double rating;
  final int played;
  final int wins;
  final int losses;
  final int draws;
  final int rank;
  final StreakType streakType;
  final int streakCount;
  final double todayDelta;
  final Medal? medal;

  double get winRate => played == 0 ? 0 : wins / played;

  @override
  List<Object?> get props => [
    seasonId,
    competitionId,
    playerId,
    displayName,
    isClaimed,
    isOwner,
    rating,
    played,
    wins,
    losses,
    draws,
    rank,
    streakType,
    streakCount,
    todayDelta,
    medal,
  ];
}

double _toDouble(Object? value) => switch (value) {
  final num n => n.toDouble(),
  final String s => double.tryParse(s) ?? 0,
  _ => 0,
};
