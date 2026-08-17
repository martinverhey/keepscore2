import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../leaderboard/domain/leaderboard.model.dart';
import '../../../leaderboard/domain/leaderboard_repository.dart';
import '../../../leaderboard/domain/medals.model.dart';
import '../../../match/domain/game_type.enum.dart';
import '../../../match/domain/match_repository.dart';
import '../../../match/presentation/cubit/game_type_filter_cubit.dart';
import '../../domain/profile_repository.dart';
import '../../domain/rating_point.model.dart';
import 'profile_overview_state.dart';

export 'profile_overview_state.dart';

class ProfileOverviewCubit extends Cubit<ProfileOverviewState> {
  ProfileOverviewCubit(
    this._leaderboardRepository,
    this._profileRepository,
    this._matchRepository,
    this._gameTypeFilterCubit,
    this.competitionId,
    this.playerId,
  ) : super(const ProfileOverviewState()) {
    _gameTypeSubscription = _gameTypeFilterCubit.stream.listen(_applyGameType);
  }

  final LeaderboardRepository _leaderboardRepository;
  final ProfileRepository _profileRepository;
  final MatchRepository _matchRepository;
  final GameTypeFilterCubit _gameTypeFilterCubit;
  final String competitionId;
  final String playerId;

  StreamSubscription<GameType?>? _gameTypeSubscription;
  String? _seasonId;
  bool _hasOpponent = false;

  Future<void> load({String? viewerPlayerId}) async {
    emit(const ProfileOverviewState());
    _hasOpponent = viewerPlayerId != null && viewerPlayerId != playerId;
    try {
      final window = await _leaderboardRepository.currentSeason(
        competitionId,
      );
      if (isClosed) return;
      _seasonId = window.id;

      final gameType = _gameTypeFilterCubit.state;
      final loaded = await _loadForGameType(gameType);
      if (isClosed || gameType != _gameTypeFilterCubit.state) return;
      emit(loaded);
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(
        ProfileOverviewState(
          status: ProfileOverviewStatus.failed,
          failure: failure,
        ),
      );
    }
  }

  Future<void> selectGameTypeFilter(GameType? gameType) =>
      _gameTypeFilterCubit.select(gameType);

  Future<void> _applyGameType(GameType? gameType) async {
    if (gameType == state.selectedGameType) return;
    if (state.status != ProfileOverviewStatus.ready) return;

    try {
      final loaded = await _loadForGameType(gameType);
      if (isClosed || gameType != _gameTypeFilterCubit.state) return;
      emit(loaded);
    } on Failure catch (failure) {
      if (isClosed || gameType != _gameTypeFilterCubit.state) return;
      emit(state.copyWith(failure: failure));
    }
  }

  Future<ProfileOverviewState> _loadForGameType(GameType? gameType) async {
    final seasonId = _seasonId;

    final statsFuture = _profileRepository.profileStats(
      playerId: playerId,
      seasonId: seasonId,
      gameType: gameType,
    );
    final recentMatchesFuture = _matchRepository.recentForPlayer(
      playerId: playerId,
      gameType: gameType,
    );
    final allMedalsFuture = _leaderboardRepository.medals(
      competitionId,
      gameType: gameType,
    );
    final leaderboardsFuture = seasonId == null
        ? null
        : _leaderboardRepository.leaderboards(
            competitionId: competitionId,
            seasonId: seasonId,
            gameType: gameType,
          );
    final ratingHistoryFuture = seasonId == null
        ? null
        : _profileRepository.ratingHistory(
            seasonId: seasonId,
            playerId: playerId,
            gameType: gameType,
          );

    final stats = await statsFuture;
    final recentMatches = await recentMatchesFuture;
    final allMedals = await allMedalsFuture;

    Medals? medals;
    for (final tally in allMedals) {
      if (tally.playerId == playerId) {
        medals = tally;
        break;
      }
    }

    Leaderboard? mine;
    var playerCount = 0;
    var history = const <RatingPoint>[];

    if (seasonId != null) {
      final leaderboards = await leaderboardsFuture!;
      history = await ratingHistoryFuture!;

      playerCount = leaderboards.length;
      for (final leaderboard in leaderboards) {
        if (leaderboard.playerId == playerId) {
          mine = leaderboard;
          break;
        }
      }
    }

    return ProfileOverviewState(
      status: ProfileOverviewStatus.ready,
      selectedGameType: gameType,
      leaderboard: mine,
      medals: medals,
      bestRating: stats.bestRating,
      playerCount: playerCount,
      history: history,
      totalPlayed: stats.totalPlayed,
      streak: stats.streak,
      bestStreaks: stats.bestStreaks,
      recentPlayed: stats.recentPlayed,
      recentMatches: recentMatches,
      hasOpponent: _hasOpponent,
    );
  }

  @override
  Future<void> close() {
    _gameTypeSubscription?.cancel();
    return super.close();
  }
}
