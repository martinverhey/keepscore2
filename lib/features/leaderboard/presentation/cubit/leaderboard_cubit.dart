import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../../../core/data/realtime.dart';
import '../../../../core/error/failure.dart';
import '../../../match/domain/game_type.dart';
import '../../../match/presentation/cubit/game_type_filter_cubit.dart';
import '../../domain/leaderboard_repository.dart';
import '../../domain/medal_tally.dart';
import '../../domain/season.dart';
import '../../domain/season_window.dart';
import 'leaderboard_state.dart';

export 'leaderboard_state.dart';

class LeaderboardCubit extends Cubit<LeaderboardState> {
  LeaderboardCubit(this._repository, this._gameTypeFilterCubit, this.competitionId)
    : super(const LeaderboardState()) {
    _gameTypeSubscription = _gameTypeFilterCubit.stream.listen(_applyGameType);
  }

  final LeaderboardRepository _repository;
  final GameTypeFilterCubit _gameTypeFilterCubit;
  final String competitionId;

  StreamSubscription<GameType?>? _gameTypeSubscription;
  DebouncedTicks? _watcher;
  String? _watchedSeasonId;
  GameType? _watchedGameType;

  Future<void> load({bool silent = false}) async {
    if (!silent) emit(const LeaderboardState());
    final gameType = _gameTypeFilterCubit.state;
    try {
      final results = await Future.wait<Object?>([
        _repository.currentSeason(competitionId),
        _repository.medalTallies(competitionId),
      ]);
      if (isClosed) return;

      final window = results[0] as SeasonWindow;
      final season = Season(
        id: window.id,
        startsAt: window.startsAt.toLocal(),
        endsAt: window.endsAt.toLocal(),
      );
      final medals = {
        for (final tally in results[1] as List<MedalTally>)
          tally.playerId: tally,
      };

      final standings = await _repository.standings(
        competitionId: competitionId,
        seasonId: season.id,
        gameType: gameType,
      );
      if (isClosed) return;

      emit(
        LeaderboardState(
          status: LeaderboardStatus.ready,
          season: season,
          selectedGameType: gameType,
          standings: standings,
          medals: medals,
        ),
      );
      _watch(season.id, gameType);
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(
        LeaderboardState(
          status: LeaderboardStatus.failed,
          season: silent ? state.season : null,
          selectedGameType: gameType,
          standings: silent ? state.standings : const [],
          medals: silent ? state.medals : const {},
          failure: failure,
        ),
      );
    }
  }

  Future<void> refresh() => load(silent: true);

  Future<void> selectGameTypeFilter(GameType? gameType) =>
      _gameTypeFilterCubit.select(gameType);

  Future<void> _applyGameType(GameType? gameType) async {
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
      final standings = await _repository.standings(
        competitionId: competitionId,
        seasonId: state.season?.id,
        gameType: gameType,
      );
      if (isClosed) return;
      emit(state.copyWith(standings: standings, busy: false));
      _watch(state.season?.id, gameType);
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(state.copyWith(busy: false, failure: failure));
    }
  }

  void _watch(String? seasonId, GameType? gameType) {
    if (_watcher != null &&
        _watchedSeasonId == seasonId &&
        _watchedGameType == gameType) {
      return;
    }
    _watcher?.cancel();
    _watchedSeasonId = seasonId;
    _watchedGameType = gameType;
    _watcher = DebouncedTicks(
      _repository.watchStandings(
        competitionId: competitionId,
        seasonId: seasonId,
        gameType: gameType,
      ),
      () {
        if (!isClosed) refresh();
      },
    );
  }

  @override
  Future<void> close() {
    _gameTypeSubscription?.cancel();
    _watcher?.cancel();
    return super.close();
  }
}
