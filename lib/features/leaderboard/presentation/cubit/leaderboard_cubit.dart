import 'package:bloc/bloc.dart';

import '../../../../core/data/realtime.dart';
import '../../../../core/error/failure.dart';
import '../../../profile/domain/profile_repository.dart';
import '../../../profile/domain/rating_point.model.dart';
import '../../domain/leaderboard_repository.dart';
import '../../domain/season.model.dart';
import 'leaderboard_state.dart';

export 'leaderboard_state.dart';

class LeaderboardCubit extends Cubit<LeaderboardState> {
  LeaderboardCubit(
    this._repository,
    this._profileRepository,
    this.competitionId,
  ) : super(const LeaderboardLoading());

  final LeaderboardRepository _repository;
  final ProfileRepository _profileRepository;
  final String competitionId;

  DebouncedTicks? _watcher;
  DebouncedTicks? _playersWatcher;
  String? _watchedSeasonId;
  String? _viewerPlayerId;

  LeaderboardReady? get _ready => switch (state) {
    LeaderboardReady ready => ready,
    _ => null,
  };

  Future<void> load({bool silent = false}) async {
    final ready = _ready;
    if (!silent) emit(const LeaderboardLoading());
    try {
      final medalsFuture = _repository.medals(competitionId);
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
      );

      final trendFuture = _viewerTrend(season.id);

      final leaderboards = await leaderboardsFuture;
      final medalTallies = await medalsFuture;
      final viewerTrend = await trendFuture;
      if (isClosed) return;

      final medals = {for (final tally in medalTallies) tally.playerId: tally};

      emit(
        LeaderboardReady(
          season: season,
          leaderboards: leaderboards,
          medals: medals,
          viewerTrend: viewerTrend,
        ),
      );
      _watch(season.id);
      _watchPlayers();
    } on Failure catch (failure) {
      if (isClosed) return;
      if (silent && ready != null) return;
      emit(LeaderboardFailed(failure));
    }
  }

  Future<void> refresh() => load(silent: true);

  Future<void> setViewer(String? playerId) async {
    if (playerId == _viewerPlayerId) return;
    _viewerPlayerId = playerId;

    final season = _ready?.season;
    if (season == null) return;

    try {
      final viewerTrend = await _viewerTrend(season.id);
      final ready = _ready;
      if (isClosed || ready == null) return;
      emit(ready.copyWith(viewerTrend: viewerTrend));
    } on Failure {
      return;
    }
  }

  Future<List<RatingPoint>> _viewerTrend(String? seasonId) async {
    final playerId = _viewerPlayerId;
    if (seasonId == null || playerId == null) return const [];
    return _profileRepository.ratingHistory(
      seasonId: seasonId,
      playerId: playerId,
    );
  }

  void _watch(String? seasonId) {
    if (_watcher != null && _watchedSeasonId == seasonId) return;
    _watcher?.cancel();
    _watchedSeasonId = seasonId;
    _watcher = DebouncedTicks(
      _repository.watchLeaderboards(
        competitionId: competitionId,
        seasonId: seasonId,
      ),
      () {
        if (!isClosed) refresh();
      },
    );
  }

  void _watchPlayers() {
    if (_playersWatcher != null) return;
    _playersWatcher = DebouncedTicks(
      _repository.watchPlayers(competitionId: competitionId),
      () {
        if (!isClosed) refresh();
      },
    );
  }

  @override
  Future<void> close() {
    _watcher?.cancel();
    _playersWatcher?.cancel();
    return super.close();
  }
}
