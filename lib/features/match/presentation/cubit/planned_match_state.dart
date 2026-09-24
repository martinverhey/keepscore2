import 'package:equatable/equatable.dart';

import '../../domain/planned_match.model.dart';

sealed class PlannedMatchState extends Equatable {
  const PlannedMatchState();

  List<PlannedMatch> get matches => const [];
}

class PlannedMatchLoading extends PlannedMatchState {
  const PlannedMatchLoading();

  @override
  List<Object?> get props => [];
}

class PlannedMatchReady extends PlannedMatchState {
  const PlannedMatchReady({
    required this.competitionId,
    this.matches = const [],
  });

  final String competitionId;

  @override
  final List<PlannedMatch> matches;

  @override
  List<Object?> get props => [competitionId, matches];
}
