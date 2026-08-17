import 'package:bloc/bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../competition/domain/competition_repository.dart';
import '../../domain/match_repository.dart';
import 'match_detail_state.dart';

export 'match_detail_state.dart';

class MatchDetailCubit extends Cubit<MatchDetailState> {
  MatchDetailCubit(
    this._matches,
    this._competitions,
    this.matchId,
    this.competitionId,
  ) : super(const MatchDetailLoading());

  final MatchRepository _matches;
  final CompetitionRepository _competitions;
  final String matchId;
  final String competitionId;

  MatchDetailReady? get _ready => switch (state) {
    MatchDetailReady ready => ready,
    _ => null,
  };

  Future<void> load() async {
    emit(const MatchDetailLoading());
    try {
      final matchFuture = _matches.byId(matchId);
      final overviewFuture = _competitions.overview(competitionId);

      final match = await matchFuture;
      final overview = await overviewFuture;
      if (isClosed) return;

      emit(
        match == null
            ? const MatchDetailMissing()
            : MatchDetailReady(
                match: match,
                competition: overview?.competition,
              ),
      );
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(MatchDetailFailed(failure));
    }
  }

  Future<bool> updateScore({required int scoreA, required int scoreB}) async {
    final ready = _ready;
    if (ready == null || ready.busy) return false;
    emit(ready.copyWith(busy: true, clearActionFailure: true));
    try {
      await _matches.updateScore(
        matchId: matchId,
        scoreA: scoreA,
        scoreB: scoreB,
      );
      if (isClosed) return true;
      final match = await _matches.byId(matchId);
      if (isClosed) return true;
      final latest = _ready;
      if (latest != null) emit(latest.copyWith(busy: false, match: match));
      return true;
    } on Failure catch (failure) {
      if (isClosed) return false;
      final latest = _ready;
      if (latest != null) {
        emit(latest.copyWith(busy: false, actionFailure: failure));
      }
      return false;
    }
  }

  Future<bool> delete() async {
    final ready = _ready;
    if (ready == null || ready.busy) return false;
    emit(ready.copyWith(busy: true, clearActionFailure: true));
    try {
      await _matches.delete(matchId);
      if (isClosed) return true;
      final latest = _ready;
      if (latest != null) emit(latest.copyWith(busy: false));
      return true;
    } on Failure catch (failure) {
      if (isClosed) return false;
      final latest = _ready;
      if (latest != null) {
        emit(latest.copyWith(busy: false, actionFailure: failure));
      }
      return false;
    }
  }
}
