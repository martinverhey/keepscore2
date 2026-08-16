import 'package:bloc/bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../leaderboard/domain/leaderboard_repository.dart';
import '../../../leaderboard/domain/season_leaderboard.model.dart';
import '../../../match/domain/game_type.enum.dart';
import 'history_state.dart';

export 'history_state.dart';

class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit(this._repository, this.competitionId)
    : super(const HistoryState());

  final LeaderboardRepository _repository;
  final String competitionId;

  Future<void> load() async {
    final gameType = state.selectedGameType;
    emit(HistoryState(selectedGameType: gameType));
    try {
      final seasons = await _repository.finishedSeasons(competitionId);
      if (isClosed) return;

      final selectedSeasonId = seasons.isEmpty ? null : seasons.first.id;
      final leaderboards = await _leaderboardsFor(selectedSeasonId, gameType);
      if (isClosed) return;

      emit(
        HistoryState(
          status: HistoryStatus.ready,
          seasons: seasons,
          selectedSeasonId: selectedSeasonId,
          leaderboards: leaderboards,
          selectedGameType: gameType,
        ),
      );
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(
        HistoryState(
          status: HistoryStatus.failed,
          selectedGameType: gameType,
          failure: failure,
        ),
      );
    }
  }

  Future<void> selectSeason(String seasonId) async {
    if (seasonId == state.selectedSeasonId) return;

    emit(
      state.copyWith(
        selectedSeasonId: seasonId,
        leaderboards: const [],
        busy: true,
        clearFailure: true,
      ),
    );

    try {
      final leaderboards = await _leaderboardsFor(
        seasonId,
        state.selectedGameType,
      );
      if (isClosed || seasonId != state.selectedSeasonId) return;
      emit(state.copyWith(leaderboards: leaderboards, busy: false));
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(state.copyWith(busy: false, failure: failure));
    }
  }

  Future<void> selectGameTypeFilter(GameType? gameType) async {
    if (gameType == state.selectedGameType) return;

    emit(
      state.copyWith(
        selectedGameType: gameType,
        clearGameType: gameType == null,
        leaderboards: const [],
        busy: true,
        clearFailure: true,
      ),
    );

    try {
      final leaderboards = await _leaderboardsFor(
        state.selectedSeasonId,
        gameType,
      );
      if (isClosed || gameType != state.selectedGameType) return;
      emit(state.copyWith(leaderboards: leaderboards, busy: false));
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(state.copyWith(busy: false, failure: failure));
    }
  }

  Future<List<SeasonLeaderboard>> _leaderboardsFor(
    String? seasonId,
    GameType? gameType,
  ) {
    if (seasonId == null) return Future.value(const []);
    return _repository.history(
      competitionId: competitionId,
      seasonId: seasonId,
      gameType: gameType,
    );
  }
}
