import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../competition/domain/competition.dart';
import '../../../competition/domain/competition_repository.dart';
import '../../domain/match_entry.dart';
import '../../domain/match_repository.dart';

enum MatchDetailStatus { loading, ready, missing, failed }

class MatchDetailState extends Equatable {
  const MatchDetailState({
    this.status = MatchDetailStatus.loading,
    this.match,
    this.competition,
    this.busy = false,
    this.failure,
    this.actionFailure,
  });

  final MatchDetailStatus status;
  final MatchEntry? match;
  final Competition? competition;
  final bool busy;
  final Failure? failure;
  final Failure? actionFailure;

  bool isManageableBy(String? userId) {
    final entry = match;
    final ownerId = competition?.ownerId;
    if (entry == null || ownerId == null) return false;
    return entry.isManageableBy(userId, ownerId: ownerId);
  }

  MatchDetailState copyWith({
    MatchDetailStatus? status,
    MatchEntry? match,
    Competition? competition,
    bool? busy,
    Failure? actionFailure,
    bool clearActionFailure = false,
  }) {
    return MatchDetailState(
      status: status ?? this.status,
      match: match ?? this.match,
      competition: competition ?? this.competition,
      busy: busy ?? this.busy,
      failure: failure,
      actionFailure: clearActionFailure
          ? null
          : (actionFailure ?? this.actionFailure),
    );
  }

  @override
  List<Object?> get props => [
    status,
    match,
    competition,
    busy,
    failure,
    actionFailure,
  ];
}

class MatchDetailCubit extends Cubit<MatchDetailState> {
  MatchDetailCubit(
    this._matches,
    this._competitions,
    this.matchId,
    this.competitionId,
  ) : super(const MatchDetailState());

  final MatchRepository _matches;
  final CompetitionRepository _competitions;
  final String matchId;
  final String competitionId;

  Future<void> load() async {
    emit(const MatchDetailState());
    try {
      final results = await Future.wait<Object?>([
        _matches.byId(matchId),
        _competitions.overview(competitionId),
      ]);
      if (isClosed) return;

      final match = results[0] as MatchEntry?;
      emit(
        MatchDetailState(
          status: match == null
              ? MatchDetailStatus.missing
              : MatchDetailStatus.ready,
          match: match,
          competition: (results[1] as CompetitionOverview?)?.competition,
        ),
      );
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(MatchDetailState(status: MatchDetailStatus.failed, failure: failure));
    }
  }

  /// The season is replayed server-side, so the numbers on this page are stale
  /// the moment the score changes — reload rather than patch.
  Future<bool> updateScore({required int scoreA, required int scoreB}) async {
    if (state.busy || state.match == null) return false;
    emit(state.copyWith(busy: true, clearActionFailure: true));
    try {
      await _matches.updateScore(
        matchId: matchId,
        scoreA: scoreA,
        scoreB: scoreB,
      );
      if (isClosed) return true;
      final match = await _matches.byId(matchId);
      if (isClosed) return true;
      emit(state.copyWith(busy: false, match: match));
      return true;
    } on Failure catch (failure) {
      if (isClosed) return false;
      emit(state.copyWith(busy: false, actionFailure: failure));
      return false;
    }
  }

  Future<bool> delete() async {
    if (state.busy || state.match == null) return false;
    emit(state.copyWith(busy: true, clearActionFailure: true));
    try {
      await _matches.delete(matchId);
      if (isClosed) return true;
      emit(state.copyWith(busy: false));
      return true;
    } on Failure catch (failure) {
      if (isClosed) return false;
      emit(state.copyWith(busy: false, actionFailure: failure));
      return false;
    }
  }
}
