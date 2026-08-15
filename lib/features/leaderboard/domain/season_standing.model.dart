import 'package:equatable/equatable.dart';

import 'medal.enum.dart';
import 'season.model.dart';

class SeasonStanding extends Equatable {
  const SeasonStanding({
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
    required this.startsAt,
    required this.endsAt,
    required this.medal,
  });

  factory SeasonStanding.fromMap(Map<String, dynamic> map) => SeasonStanding(
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
    startsAt: DateTime.parse(map['starts_at'] as String).toLocal(),
    endsAt: DateTime.parse(map['ends_at'] as String).toLocal(),
    medal: Medal.fromWire(map['medal'] as String?),
  );

  final String seasonId;
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
  final DateTime startsAt;
  final DateTime endsAt;
  final Medal? medal;

  Season get season => Season(id: seasonId, startsAt: startsAt, endsAt: endsAt);

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
    startsAt,
    endsAt,
    medal,
  ];
}

double _toDouble(Object? value) => switch (value) {
  final num n => n.toDouble(),
  final String s => double.tryParse(s) ?? 0,
  _ => 0,
};
