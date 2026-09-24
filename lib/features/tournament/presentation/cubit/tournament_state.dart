import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/tournament_run.model.dart';

sealed class TournamentState extends Equatable {
  const TournamentState();
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
    required this.runs,
    this.busy = false,
    this.actionFailure,
  });

  final List<TournamentRun> runs;
  final bool busy;
  final Failure? actionFailure;

  TournamentRun get latest => runs.first;

  bool get hasRunning => !latest.isCompleted;

  TournamentRun? get running => hasRunning ? latest : null;

  List<TournamentRun> get finished => [
    for (final run in runs)
      if (run.isCompleted) run,
  ];

  TournamentRun? runOf(String tournamentId) {
    for (final run in runs) {
      if (run.id == tournamentId) return run;
    }
    return null;
  }

  TournamentReady copyWith({
    List<TournamentRun>? runs,
    bool? busy,
    Failure? actionFailure,
    bool clearActionFailure = false,
  }) {
    return TournamentReady(
      runs: runs ?? this.runs,
      busy: busy ?? this.busy,
      actionFailure: clearActionFailure
          ? null
          : (actionFailure ?? this.actionFailure),
    );
  }

  @override
  List<Object?> get props => [runs, busy, actionFailure];
}
