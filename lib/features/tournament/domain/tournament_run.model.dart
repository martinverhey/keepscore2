import 'package:equatable/equatable.dart';

import 'bracket.model.dart';
import 'tournament.model.dart';

class TournamentRun extends Equatable {
  const TournamentRun({required this.tournament, required this.bracket});

  final Tournament tournament;
  final Bracket bracket;

  String get id => tournament.id;

  bool get isCompleted => tournament.isCompleted;

  DateTime get finishedAt => tournament.completedAt ?? tournament.createdAt;

  TournamentEntrant? get champion => bracket.champion;

  @override
  List<Object?> get props => [tournament, bracket];
}
