import 'package:equatable/equatable.dart';

import 'tournament_status.enum.dart';

export 'tournament_status.enum.dart';

class Tournament extends Equatable {
  const Tournament({
    required this.id,
    required this.competitionId,
    required this.seasonId,
    required this.size,
    required this.status,
    required this.createdAt,
    this.winnerPlayerId,
    this.createdBy,
    this.completedAt,
  });

  factory Tournament.fromMap(Map<String, dynamic> map) => Tournament(
    id: map['id'] as String,
    competitionId: map['competition_id'] as String,
    seasonId: map['season_id'] as String,
    size: (map['size'] as num).toInt(),
    status: TournamentStatus.fromWire(map['status'] as String),
    createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    winnerPlayerId: map['winner_player_id'] as String?,
    createdBy: map['created_by'] as String?,
    completedAt: switch (map['completed_at']) {
      final String value => DateTime.parse(value).toLocal(),
      _ => null,
    },
  );

  final String id;
  final String competitionId;
  final String seasonId;
  final int size;
  final TournamentStatus status;
  final DateTime createdAt;
  final String? winnerPlayerId;
  final String? createdBy;
  final DateTime? completedAt;

  bool get isCompleted => status == TournamentStatus.completed;

  bool isManageableBy(String? userId, {required String ownerId}) =>
      userId != null && (userId == createdBy || userId == ownerId);

  @override
  List<Object?> get props => [
    id,
    competitionId,
    seasonId,
    size,
    status,
    createdAt,
    winnerPlayerId,
    createdBy,
    completedAt,
  ];
}
