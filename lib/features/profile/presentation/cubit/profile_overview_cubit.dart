import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../leaderboard/domain/leaderboard.model.dart';
import '../../../leaderboard/domain/leaderboard_repository.dart';
import '../../../leaderboard/domain/medals.model.dart';
import '../../../match/domain/game_type.enum.dart';
import '../../../match/domain/match_entry.model.dart';
import '../../../match/domain/match_repository.dart';
import '../../../match/presentation/cubit/game_type_filter_cubit.dart';
import '../../domain/best_streaks.model.dart';
import '../../domain/profile_repository.dart';
import '../../domain/rating_point.model.dart';
import '../../domain/recent_played.model.dart';
import '../../domain/streak.model.dart';
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

    final results = await Future.wait<Object?>([
      _profileRepository.totalMatchesPlayed(
        playerId: playerId,
        gameType: gameType,
      ),
      _matchRepository.recentForPlayer(playerId: playerId, gameType: gameType),
      _profileRepository.bestStreaks(playerId: playerId, gameType: gameType),
      _leaderboardRepository.medals(competitionId, gameType: gameType),
      _profileRepository.bestRating(playerId: playerId, gameType: gameType),
      if (seasonId != null)
        _leaderboardRepository.leaderboards(
          competitionId: competitionId,
          seasonId: seasonId,
          gameType: gameType,
        ),
      if (seasonId != null)
        _profileRepository.ratingHistory(
          seasonId: seasonId,
          playerId: playerId,
          gameType: gameType,
        ),
      if (seasonId != null)
        _profileRepository.currentStreak(
          seasonId: seasonId,
          playerId: playerId,
          gameType: gameType,
        ),
      if (seasonId != null)
        _profileRepository.recentPlayed(
          seasonId: seasonId,
          playerId: playerId,
          gameType: gameType,
        ),
    ]);

    final totalPlayed = results[0] as int;
    final recentMatches = results[1] as List<MatchEntry>;
    final bestStreaks = results[2] as BestStreaks;
    final allMedals = results[3] as List<Medals>;
    final bestRating = results[4] as double;

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
    var streak = const Streak.none();
    var recentPlayed = const RecentPlayed.zero();

    if (seasonId != null) {
      var next = 5;
      final leaderboards = results[next++] as List<Leaderboard>;
      history = results[next++] as List<RatingPoint>;
      streak = results[next++] as Streak;
      recentPlayed = results[next++] as RecentPlayed;

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
      bestRating: bestRating,
      playerCount: playerCount,
      history: history,
      totalPlayed: totalPlayed,
      streak: streak,
      bestStreaks: bestStreaks,
      recentPlayed: recentPlayed,
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
