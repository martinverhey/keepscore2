import 'package:equatable/equatable.dart';

import 'competition.dart';

class CompetitionOverview extends Equatable {
  const CompetitionOverview({
    required this.competition,
    required this.playerCount,
    required this.matchCount,
    this.lastPlayedAt,
    this.myPlayerId,
  });

  factory CompetitionOverview.fromMap(Map<String, dynamic> map) =>
      CompetitionOverview(
        competition: Competition.fromMap(map),
        playerCount: (map['player_count'] as num?)?.toInt() ?? 0,
        matchCount: (map['match_count'] as num?)?.toInt() ?? 0,
        lastPlayedAt: map['last_played_at'] == null
            ? null
            : DateTime.parse(map['last_played_at'] as String),
        myPlayerId: map['my_player_id'] as String?,
      );

  final Competition competition;
  final int playerCount;
  final int matchCount;
  final DateTime? lastPlayedAt;
  final String? myPlayerId;

  String get id => competition.id;

  @override
  List<Object?> get props => [
    competition,
    playerCount,
    matchCount,
    lastPlayedAt,
    myPlayerId,
  ];
}
