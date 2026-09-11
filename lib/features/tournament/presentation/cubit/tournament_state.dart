import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/bracket.model.dart';
import '../../domain/tournament.model.dart';

sealed class TournamentState extends Equatable {
  const TournamentState();

  Tournament? get tournament => null;
}

class TournamentLoading extends TournamentState {
  const TournamentLoading();

  @override
  List<Object?> get props => [];
}

class TournamentMissing extends TournamentState {
  const TournamentMissing();

  @override
  List<Object?> get props => [];
}

class TournamentFailed extends TournamentState {
  const TournamentFailed(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

class TournamentReady extends TournamentState {
  const TournamentReady({
    required this.tournament,
    required this.bracket,
    this.busy = false,
    this.actionFailure,
  });

  @override
  final Tournament tournament;

  final Bracket bracket;
  final bool busy;
  final Failure? actionFailure;

  bool get isCompleted => tournament.isCompleted;

  TournamentEntrant? get champion => bracket.champion;

  TournamentReady copyWith({
    Tournament? tournament,
    Bracket? bracket,
    bool? busy,
    Failure? actionFailure,
    bool clearActionFailure = false,
  }) {
    return TournamentReady(
      tournament: tournament ?? this.tournament,
      bracket: bracket ?? this.bracket,
      busy: busy ?? this.busy,
      actionFailure: clearActionFailure
          ? null
          : (actionFailure ?? this.actionFailure),
    );
  }

  @override
  List<Object?> get props => [tournament, bracket, busy, actionFailure];
}
