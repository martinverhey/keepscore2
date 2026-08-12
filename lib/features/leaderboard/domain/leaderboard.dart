import 'package:equatable/equatable.dart';

class Leaderboard extends Equatable {
  const Leaderboard({
    required this.seasonId,
    required this.competitionId,
    required this.playerId,
    required this.displayName,
    required this.isClaimed,
    required this.rating,
    required this.played,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.rank,
  });

  factory Leaderboard.fromMap(Map<String, dynamic> map) => Leaderboard(
    seasonId: map['season_id'] as String,
    competitionId: map['competition_id'] as String,
    playerId: map['player_id'] as String,
    displayName: map['display_name'] as String,
    isClaimed: map['is_claimed'] as bool? ?? false,
    rating: _toDouble(map['rating']),
    played: (map['played'] as num?)?.toInt() ?? 0,
    wins: (map['wins'] as num?)?.toInt() ?? 0,
    losses: (map['losses'] as num?)?.toInt() ?? 0,
    draws: (map['draws'] as num?)?.toInt() ?? 0,
    rank: (map['rank'] as num?)?.toInt() ?? 0,
  );

  factory Leaderboard.forRosterPlayer(
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
  final double rating;
  final int played;
  final int wins;
  final int losses;
  final int draws;
  final int rank;

  @override
  List<Object?> get props => [
    seasonId,
    competitionId,
    playerId,
    displayName,
    isClaimed,
    rating,
    played,
    wins,
    losses,
    draws,
    rank,
  ];
}

double _toDouble(Object? value) => switch (value) {
  final num n => n.toDouble(),
  final String s => double.tryParse(s) ?? 0,
  _ => 0,
};
