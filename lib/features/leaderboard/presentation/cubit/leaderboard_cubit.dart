import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../../../core/data/realtime.dart';
import '../../../../core/error/failure.dart';
import '../../../match/domain/game_type.enum.dart';
import '../../../match/presentation/cubit/game_type_filter_cubit.dart';
import '../../domain/leaderboard.model.dart';
import '../../domain/leaderboard_repository.dart';
import '../../domain/medals.model.dart';
import '../../domain/season.model.dart';
import 'leaderboard_state.dart';

export 'leaderboard_state.dart';

class LeaderboardCubit extends Cubit<LeaderboardState> {
  LeaderboardCubit(
    this._repository,
    this._gameTypeFilterCubit,
    this.competitionId,
  ) : super(const LeaderboardState()) {
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
      // medals doesn't depend on the season, so it's kicked off up front and
      // only awaited once leaderboards (which does depend on it) is also in
      // flight — instead of blocking the season lookup on it first.
      final medalsFuture = _repository.medals(competitionId, gameType: gameType);
      final window = await _repository.currentSeason(competitionId);
      if (isClosed) return;

      final season = Season(
        id: window.id,
        startsAt: window.startsAt.toLocal(),
        endsAt: window.endsAt.toLocal(),
      );

      final results = await Future.wait<Object?>([
        _repository.leaderboards(
          competitionId: competitionId,
          seasonId: season.id,
          gameType: gameType,
        ),
        medalsFuture,
      ]);
      if (isClosed || gameType != _gameTypeFilterCubit.state) return;

      final leaderboards = results[0] as List<Leaderboard>;
      final medals = {
        for (final tally in results[1] as List<Medals>) tally.playerId: tally,
      };

      emit(
        LeaderboardState(
          status: LeaderboardStatus.ready,
          season: season,
          selectedGameType: gameType,
          leaderboards: leaderboards,
          medals: medals,
        ),
      );
      _watch(season.id, gameType);
    } on Failure catch (failure) {
      if (isClosed || gameType != _gameTypeFilterCubit.state) return;
      emit(
        LeaderboardState(
          status: LeaderboardStatus.failed,
          season: silent ? state.season : null,
          selectedGameType: gameType,
          leaderboards: silent ? state.leaderboards : const [],
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
        leaderboards: const [],
        busy: true,
        clearFailure: true,
      ),
    );

    try {
      final results = await Future.wait<Object?>([
        _repository.leaderboards(
          competitionId: competitionId,
          seasonId: state.season?.id,
          gameType: gameType,
        ),
        _repository.medals(competitionId, gameType: gameType),
      ]);
      if (isClosed || gameType != _gameTypeFilterCubit.state) return;

      final leaderboards = results[0] as List<Leaderboard>;
      final medals = {
        for (final tally in results[1] as List<Medals>) tally.playerId: tally,
      };

      emit(
        state.copyWith(leaderboards: leaderboards, medals: medals, busy: false),
      );
      _watch(state.season?.id, gameType);
    } on Failure catch (failure) {
      if (isClosed || gameType != _gameTypeFilterCubit.state) return;
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
      _repository.watchLeaderboards(
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
