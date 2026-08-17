import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../../../core/data/realtime.dart';
import '../../../../core/error/failure.dart';
import '../../../match/domain/game_type.enum.dart';
import '../../../match/presentation/cubit/game_type_filter_cubit.dart';
import '../../domain/leaderboard_repository.dart';
import '../../domain/season.model.dart';
import 'leaderboard_state.dart';

export 'leaderboard_state.dart';

class LeaderboardCubit extends Cubit<LeaderboardState> {
  LeaderboardCubit(
    this._repository,
    this._gameTypeFilterCubit,
    this.competitionId,
  ) : super(const LeaderboardLoading()) {
    _gameTypeSubscription = _gameTypeFilterCubit.stream.listen(_applyGameType);
  }

  final LeaderboardRepository _repository;
  final GameTypeFilterCubit _gameTypeFilterCubit;
  final String competitionId;

  StreamSubscription<GameType?>? _gameTypeSubscription;
  DebouncedTicks? _watcher;
  String? _watchedSeasonId;
  GameType? _watchedGameType;

  LeaderboardReady? get _ready => switch (state) {
    LeaderboardReady ready => ready,
    _ => null,
  };

  Future<void> load({bool silent = false}) async {
    final ready = _ready;
    if (!silent) emit(const LeaderboardLoading());
    final gameType = _gameTypeFilterCubit.state;
    try {
      final medalsFuture = _repository.medals(
        competitionId,
        gameType: gameType,
      );
      final window = await _repository.currentSeason(competitionId);
      if (isClosed) return;

      final season = Season(
        id: window.id,
        startsAt: window.startsAt.toLocal(),
        endsAt: window.endsAt.toLocal(),
      );

      final leaderboardsFuture = _repository.leaderboards(
        competitionId: competitionId,
        seasonId: season.id,
        gameType: gameType,
      );

      final leaderboards = await leaderboardsFuture;
      final medalTallies = await medalsFuture;
      if (isClosed || gameType != _gameTypeFilterCubit.state) return;

      final medals = {for (final tally in medalTallies) tally.playerId: tally};

      emit(
        LeaderboardReady(
          season: season,
          selectedGameType: gameType,
          leaderboards: leaderboards,
          medals: medals,
        ),
      );
      _watch(season.id, gameType);
    } on Failure catch (failure) {
      if (isClosed || gameType != _gameTypeFilterCubit.state) return;
      if (silent && ready != null) return;
      emit(LeaderboardFailed(failure));
    }
  }

  Future<void> refresh() => load(silent: true);

  Future<void> selectGameTypeFilter(GameType? gameType) =>
      _gameTypeFilterCubit.select(gameType);

  Future<void> _applyGameType(GameType? gameType) async {
    final ready = _ready;
    if (ready == null || gameType == ready.selectedGameType) return;

    emit(
      ready.copyWith(
        selectedGameType: gameType,
        clearGameType: gameType == null,
        leaderboards: const [],
        busy: true,
      ),
    );

    try {
      final leaderboardsFuture = _repository.leaderboards(
        competitionId: competitionId,
        seasonId: ready.season.id,
        gameType: gameType,
      );
      final medalsFuture = _repository.medals(
        competitionId,
        gameType: gameType,
      );

      final leaderboards = await leaderboardsFuture;
      final medalTallies = await medalsFuture;
      if (isClosed || gameType != _gameTypeFilterCubit.state) return;

      final medals = {for (final tally in medalTallies) tally.playerId: tally};

      final latest = _ready;
      if (latest == null) return;
      emit(
        latest.copyWith(
          leaderboards: leaderboards,
          medals: medals,
          busy: false,
        ),
      );
      _watch(ready.season.id, gameType);
    } on Failure {
      if (isClosed || gameType != _gameTypeFilterCubit.state) return;
      final latest = _ready;
      if (latest != null) emit(latest.copyWith(busy: false));
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
