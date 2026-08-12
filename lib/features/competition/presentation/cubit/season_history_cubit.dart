import 'package:bloc/bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../leaderboard/domain/leaderboard_repository.dart';
import '../../../leaderboard/domain/season_standing.dart';
import '../../../match/domain/game_type.dart';
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
      final standings = await _repository.seasonHistory(
        competitionId: competitionId,
        gameType: gameType,
      );
      if (isClosed) return;
      emit(
        SeasonHistoryState(
          status: SeasonHistoryStatus.ready,
          groups: _group(standings),
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

  Future<void> selectGameTypeFilter(GameType? gameType) async {
    if (gameType == state.selectedGameType) return;

    emit(
      state.copyWith(
        selectedGameType: gameType,
        clearGameType: gameType == null,
        groups: const [],
        busy: true,
        clearFailure: true,
      ),
    );

    try {
      final standings = await _repository.seasonHistory(
        competitionId: competitionId,
        gameType: gameType,
      );
      if (isClosed) return;
      emit(state.copyWith(groups: _group(standings), busy: false));
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(state.copyWith(busy: false, failure: failure));
    }
  }

  List<SeasonHistoryGroup> _group(List<SeasonStanding> standings) {
    final groups = <String, SeasonHistoryGroup>{};
    for (final standing in standings) {
      final existing = groups[standing.seasonId];
      groups[standing.seasonId] = (
        seasonId: standing.seasonId,
        startsAt: standing.startsAt,
        endsAt: standing.endsAt,
        standings: [...(existing?.standings ?? const []), standing],
      );
    }
    final result = groups.values.toList()
      ..sort((a, b) => b.startsAt.compareTo(a.startsAt));
    return result;
  }
}
