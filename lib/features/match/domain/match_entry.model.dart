import 'package:equatable/equatable.dart';

import 'match_participant.model.dart';
import 'match_team.enum.dart';

export 'match_participant.model.dart';
export 'match_team.enum.dart';

class MatchEntry extends Equatable {
  const MatchEntry({
    required this.id,
    required this.competitionId,
    required this.seasonId,
    required this.playedAt,
    required this.teamAScore,
    required this.teamBScore,
    required this.teamARating,
    required this.teamBRating,
    required this.teamA,
    required this.teamB,
    this.createdBy,
  });

  factory MatchEntry.fromMap(Map<String, dynamic> map) => MatchEntry(
    id: map['id'] as String,
    competitionId: map['competition_id'] as String,
    seasonId: map['season_id'] as String,
    playedAt: DateTime.parse(map['played_at'] as String).toLocal(),
    teamAScore: (map['team_a_score'] as num).toInt(),
    teamBScore: (map['team_b_score'] as num).toInt(),
    teamARating: _toDouble(map['team_a_rating']),
    teamBRating: _toDouble(map['team_b_rating']),
    createdBy: map['created_by'] as String?,
    teamA: _roster(map['team_a']),
    teamB: _roster(map['team_b']),
  );

  final String id;
  final String competitionId;
  final String seasonId;
  final DateTime playedAt;
  final int teamAScore;
  final int teamBScore;
  final double teamARating;
  final double teamBRating;
  final List<MatchParticipant> teamA;
  final List<MatchParticipant> teamB;
  final String? createdBy;

  bool get isDraw => teamAScore == teamBScore;

  MatchTeam? get winner => isDraw
      ? null
      : teamAScore > teamBScore
      ? MatchTeam.a
      : MatchTeam.b;

  double get deltaA => teamA.isEmpty ? 0 : teamA.first.ratingDelta;

  List<MatchParticipant> roster(MatchTeam team) =>
      team == MatchTeam.a ? teamA : teamB;

  int score(MatchTeam team) => team == MatchTeam.a ? teamAScore : teamBScore;

  bool isManageableBy(String? userId, {required String ownerId}) =>
      userId != null && (userId == createdBy || userId == ownerId);

  @override
  List<Object?> get props => [
    id,
    competitionId,
    seasonId,
    playedAt,
    teamAScore,
    teamBScore,
    teamARating,
    teamBRating,
    teamA,
    teamB,
    createdBy,
  ];
}

List<MatchParticipant> _roster(Object? value) => switch (value) {
  final List<dynamic> rows =>
    rows
        .map((row) => MatchParticipant.fromMap(row as Map<String, dynamic>))
        .toList(growable: false),
  _ => const [],
};

double _toDouble(Object? value) => switch (value) {
  final num n => n.toDouble(),
  final String s => double.tryParse(s) ?? 0,
  _ => 0,
};
