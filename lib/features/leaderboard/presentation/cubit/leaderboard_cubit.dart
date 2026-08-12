import 'package:bloc/bloc.dart';

import '../../../../core/data/realtime.dart';
import '../../../../core/error/failure.dart';
import '../../../match/domain/game_type.dart';
import '../../domain/leaderboard_repository.dart';
import '../../domain/medal_tally.dart';
import '../../domain/season.dart';
import '../../domain/season_window.dart';
import 'leaderboard_state.dart';

export 'leaderboard_state.dart';

class LeaderboardCubit extends Cubit<LeaderboardState> {
  LeaderboardCubit(this._repository, this.competitionId)
    : super(const LeaderboardState());

  final LeaderboardRepository _repository;
  final String competitionId;

  DebouncedTicks? _watcher;
  String? _watchedSeasonId;
  GameType? _watchedGameType;

  Future<void> load({bool silent = false}) async {
    if (!silent) emit(const LeaderboardState());
    final gameType = state.selectedGameType;
    try {
      final results = await Future.wait<Object?>([
        _repository.currentSeason(competitionId),
        _repository.seasons(competitionId),
        _repository.medalTallies(competitionId),
      ]);
      if (isClosed) return;

      final seasons = _withCurrentWindow(
        results[1] as List<Season>,
        results[0] as SeasonWindow,
      );
      final selected = _pick(seasons, state.selectedStartsAt);
      final medals = {
        for (final tally in results[2] as List<MedalTally>)
          tally.playerId: tally,
      };

      final standings = await _repository.standings(
        competitionId: competitionId,
        seasonId: selected?.id,
        gameType: gameType,
      );
      if (isClosed) return;

      emit(
        LeaderboardState(
          status: LeaderboardStatus.ready,
          seasons: seasons,
          selectedStartsAt: selected?.startsAt,
          selectedGameType: gameType,
          standings: standings,
          medals: medals,
        ),
      );
      _watch(selected?.id, gameType);
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(
        LeaderboardState(
          status: LeaderboardStatus.failed,
          seasons: silent ? state.seasons : const [],
          selectedStartsAt: state.selectedStartsAt,
          selectedGameType: gameType,
          standings: silent ? state.standings : const [],
          medals: silent ? state.medals : const {},
          failure: failure,
        ),
      );
    }
  }

  Future<void> refresh() => load(silent: true);

  Future<void> selectSeason(DateTime startsAt) async {
    final season = _pick(state.seasons, startsAt);
    if (season == null || season == state.selectedSeason) return;

    emit(
      state.copyWith(
        selectedStartsAt: season.startsAt,
        standings: const [],
        busy: true,
        clearFailure: true,
      ),
    );

    try {
      final standings = await _repository.standings(
        competitionId: competitionId,
        seasonId: season.id,
        gameType: state.selectedGameType,
      );
      if (isClosed) return;
      emit(state.copyWith(standings: standings, busy: false));
      _watch(season.id, state.selectedGameType);
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
      final standings = await _repository.standings(
        competitionId: competitionId,
        seasonId: state.selectedSeason?.id,
        gameType: gameType,
      );
      if (isClosed) return;
      emit(state.copyWith(standings: standings, busy: false));
      _watch(state.selectedSeason?.id, gameType);
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(state.copyWith(busy: false, failure: failure));
    }
  }

  List<Season> _withCurrentWindow(List<Season> stored, SeasonWindow window) {
    final known = stored.any(
      (season) => season.startsAt.isAtSameMomentAs(window.startsAt),
    );
    if (known) return stored;
    return [
      Season(
        id: window.id,
        startsAt: window.startsAt.toLocal(),
        endsAt: window.endsAt.toLocal(),
      ),
      ...stored,
    ];
  }

  Season? _pick(List<Season> seasons, DateTime? startsAt) {
    if (seasons.isEmpty) return null;
    if (startsAt == null) return seasons.first;
    for (final season in seasons) {
      if (season.startsAt.isAtSameMomentAs(startsAt)) return season;
    }
    return seasons.first;
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
    _watcher?.cancel();
    return super.close();
  }
}
