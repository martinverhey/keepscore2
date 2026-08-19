import 'package:bloc/bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../leaderboard/domain/leaderboard_repository.dart';
import '../../../leaderboard/domain/season_leaderboard.model.dart';
import 'history_state.dart';

export 'history_state.dart';

class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit(this._repository, this.competitionId)
    : super(const HistoryLoading());

  final LeaderboardRepository _repository;
  final String competitionId;

  HistoryReady? get _ready => switch (state) {
    HistoryReady ready => ready,
    _ => null,
  };

  Future<void> load() async {
    emit(const HistoryLoading());
    try {
      final seasons = await _repository.finishedSeasons(competitionId);
      if (isClosed) return;

      final selectedSeasonId = seasons.isEmpty ? null : seasons.first.id;
      final leaderboards = await _leaderboardsFor(selectedSeasonId);
      if (isClosed) return;

      emit(
        HistoryReady(
          seasons: seasons,
          selectedSeasonId: selectedSeasonId,
          leaderboards: leaderboards,
        ),
      );
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(HistoryFailed(failure));
    }
  }

  Future<void> selectSeason(String seasonId) async {
    final ready = _ready;
    if (ready == null || seasonId == ready.selectedSeasonId) return;

    emit(
      ready.copyWith(
        selectedSeasonId: seasonId,
        leaderboards: const [],
        busy: true,
      ),
    );

    try {
      final leaderboards = await _leaderboardsFor(seasonId);
      if (isClosed) return;
      final latest = _ready;
      if (latest == null || seasonId != latest.selectedSeasonId) return;
      emit(latest.copyWith(leaderboards: leaderboards, busy: false));
    } on Failure {
      if (isClosed) return;
      final latest = _ready;
      if (latest != null) emit(latest.copyWith(busy: false));
    }
  }

  Future<List<SeasonLeaderboard>> _leaderboardsFor(String? seasonId) {
    if (seasonId == null) return Future.value(const []);
    return _repository.history(
      competitionId: competitionId,
      seasonId: seasonId,
    );
  }
}
