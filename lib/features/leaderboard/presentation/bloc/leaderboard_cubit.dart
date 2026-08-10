import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/data/realtime.dart';
import '../../../../core/error/failure.dart';
import '../../domain/leaderboard_repository.dart';
import '../../domain/season.dart';
import '../../domain/season_window.dart';
import '../../domain/standing.dart';

enum LeaderboardStatus { loading, ready, failed }

class LeaderboardState extends Equatable {
  const LeaderboardState({
    this.status = LeaderboardStatus.loading,
    this.seasons = const [],
    this.selectedStartsAt,
    this.standings = const [],
    this.busy = false,
    this.failure,
  });

  final LeaderboardStatus status;

  /// Newest first. The window the competition is currently playing for is
  /// always the first entry, whether or not it has a row in `seasons` yet.
  final List<Season> seasons;

  final DateTime? selectedStartsAt;
  final List<Standing> standings;

  /// A season switch is in flight.
  final bool busy;

  final Failure? failure;

  Season? get currentSeason => seasons.isEmpty ? null : seasons.first;

  Season? get selectedSeason {
    if (seasons.isEmpty) return null;
    for (final season in seasons) {
      if (selectedStartsAt != null &&
          season.startsAt.isAtSameMomentAs(selectedStartsAt!)) {
        return season;
      }
    }
    return seasons.first;
  }

  bool get isShowingCurrentSeason => selectedSeason == currentSeason;

  bool get hasHistory => seasons.length > 1;

  LeaderboardState copyWith({
    LeaderboardStatus? status,
    List<Season>? seasons,
    DateTime? selectedStartsAt,
    List<Standing>? standings,
    bool? busy,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return LeaderboardState(
      status: status ?? this.status,
      seasons: seasons ?? this.seasons,
      selectedStartsAt: selectedStartsAt ?? this.selectedStartsAt,
      standings: standings ?? this.standings,
      busy: busy ?? this.busy,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [
    status,
    seasons,
    selectedStartsAt,
    standings,
    busy,
    failure,
  ];
}

/// The standings of one season, kept live.
///
/// Ratings are never patched from a realtime payload: a rank is a property of
/// the whole table, and an edit replays the season, so a tick means "refetch".
class LeaderboardCubit extends Cubit<LeaderboardState> {
  LeaderboardCubit(this._repository, this.competitionId)
    : super(const LeaderboardState());

  final LeaderboardRepository _repository;
  final String competitionId;

  DebouncedTicks? _watcher;
  String? _watchedSeasonId;

  Future<void> load({bool silent = false}) async {
    if (!silent) emit(const LeaderboardState());
    try {
      final results = await Future.wait<Object?>([
        _repository.currentSeason(competitionId),
        _repository.seasons(competitionId),
      ]);
      if (isClosed) return;

      final seasons = _withCurrentWindow(
        results[1] as List<Season>,
        results[0] as SeasonWindow,
      );
      final selected = _pick(seasons, state.selectedStartsAt);

      final standings = await _repository.standings(
        competitionId: competitionId,
        seasonId: selected?.id,
      );
      if (isClosed) return;

      emit(
        LeaderboardState(
          status: LeaderboardStatus.ready,
          seasons: seasons,
          selectedStartsAt: selected?.startsAt,
          standings: standings,
        ),
      );
      _watch(selected?.id);
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(
        LeaderboardState(
          status: LeaderboardStatus.failed,
          seasons: silent ? state.seasons : const [],
          selectedStartsAt: state.selectedStartsAt,
          standings: silent ? state.standings : const [],
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
      );
      if (isClosed) return;
      emit(state.copyWith(standings: standings, busy: false));
      _watch(season.id);
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(state.copyWith(busy: false, failure: failure));
    }
  }

  /// `seasons` only gets a row once a match lands in it, so the window the
  /// competition is currently playing for has to be stitched in by hand.
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

  void _watch(String? seasonId) {
    if (_watcher != null && _watchedSeasonId == seasonId) return;
    _watcher?.cancel();
    _watchedSeasonId = seasonId;
    _watcher = DebouncedTicks(
      _repository.watchStandings(
        competitionId: competitionId,
        seasonId: seasonId,
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
