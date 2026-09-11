import 'package:bloc/bloc.dart';

import '../../../../core/data/realtime.dart';
import '../../../../core/error/failure.dart';
import '../../domain/tournament_repository.dart';
import 'tournament_state.dart';

export 'tournament_state.dart';

class TournamentCubit extends Cubit<TournamentState> {
  TournamentCubit(this._repository, this.competitionId)
    : super(const TournamentLoading());

  final TournamentRepository _repository;
  final String competitionId;

  DebouncedTicks? _watcher;
  DebouncedTicks? _bracketWatcher;
  String? _watchedTournamentId;

  TournamentReady? get _ready => switch (state) {
    TournamentReady ready => ready,
    _ => null,
  };

  Future<void> load({bool silent = false}) async {
    final ready = _ready;
    if (!silent) emit(const TournamentLoading());
    _watch();

    try {
      final tournament = await _repository.latest(competitionId);
      if (isClosed) return;

      if (tournament == null) {
        _watchBracket(null);
        emit(const TournamentMissing());
        return;
      }

      final bracket = await _repository.bracket(tournament.id);
      if (isClosed) return;

      _watchBracket(tournament.id);
      emit(TournamentReady(tournament: tournament, bracket: bracket));
    } on Failure catch (failure) {
      if (isClosed) return;
      if (silent && ready != null) return;
      emit(TournamentFailed(failure));
    }
  }

  Future<void> refresh() => load(silent: true);

  Future<bool> setResult({
    required String tournamentMatchId,
    required int scoreA,
    required int scoreB,
  }) async {
    final ready = _ready;
    if (ready == null) return false;
    emit(ready.copyWith(busy: true, clearActionFailure: true));

    try {
      await _repository.setResult(
        tournamentMatchId: tournamentMatchId,
        scoreA: scoreA,
        scoreB: scoreB,
      );
      if (isClosed) return false;
      await load(silent: true);
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

  Future<bool> cancel() async {
    final ready = _ready;
    if (ready == null) return false;
    emit(ready.copyWith(busy: true, clearActionFailure: true));

    try {
      await _repository.cancel(ready.tournament.id);
      if (isClosed) return false;
      await load(silent: true);
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

  void _watch() {
    _watcher ??= DebouncedTicks(_repository.watchTournaments(competitionId), () {
      if (!isClosed) refresh();
    });
  }

  void _watchBracket(String? tournamentId) {
    if (_bracketWatcher != null && _watchedTournamentId == tournamentId) return;
    _bracketWatcher?.cancel();
    _bracketWatcher = null;
    _watchedTournamentId = tournamentId;
    if (tournamentId == null) return;

    _bracketWatcher = DebouncedTicks(_repository.watchBracket(tournamentId), () {
      if (!isClosed) refresh();
    });
  }

  @override
  Future<void> close() {
    _watcher?.cancel();
    _bracketWatcher?.cancel();
    return super.close();
  }
}
