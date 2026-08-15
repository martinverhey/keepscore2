import 'package:bloc/bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../leaderboard/domain/leaderboard_repository.dart';
import '../../../leaderboard/domain/season_standing.model.dart';
import '../../../match/domain/game_type.enum.dart';
import 'season_history_state.dart';

export 'season_history_state.dart';

class SeasonHistoryCubit extends Cubit<SeasonHistoryState> {
  SeasonHistoryCubit(this._repository, this.competitionId)
    : super(const SeasonHistoryState());

  final LeaderboardRepository _repository;
  final String competitionId;

  Future<void> load() async {
    final gameType = state.selectedGameType;
    emit(SeasonHistoryState(selectedGameType: gameType));
    try {
      final seasons = await _repository.finishedSeasons(competitionId);
      if (isClosed) return;

      final selectedSeasonId = seasons.isEmpty ? null : seasons.first.id;
      final standings = await _standingsFor(selectedSeasonId, gameType);
      if (isClosed) return;

      emit(
        SeasonHistoryState(
          status: SeasonHistoryStatus.ready,
          seasons: seasons,
          selectedSeasonId: selectedSeasonId,
          standings: standings,
          selectedGameType: gameType,
        ),
      );
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(
        SeasonHistoryState(
          status: SeasonHistoryStatus.failed,
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
        standings: const [],
        busy: true,
        clearFailure: true,
      ),
    );

    try {
      final standings = await _standingsFor(seasonId, state.selectedGameType);
      if (isClosed || seasonId != state.selectedSeasonId) return;
      emit(state.copyWith(standings: standings, busy: false));
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
        standings: const [],
        busy: true,
        clearFailure: true,
      ),
    );

    try {
      final standings = await _standingsFor(state.selectedSeasonId, gameType);
      if (isClosed || gameType != state.selectedGameType) return;
      emit(state.copyWith(standings: standings, busy: false));
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(state.copyWith(busy: false, failure: failure));
    }
  }

  Future<List<SeasonStanding>> _standingsFor(
    String? seasonId,
    GameType? gameType,
  ) {
    if (seasonId == null) return Future.value(const []);
    return _repository.seasonHistory(
      competitionId: competitionId,
      seasonId: seasonId,
      gameType: gameType,
    );
  }
}
