import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../leaderboard/domain/leaderboard.model.dart';
import '../../../leaderboard/domain/leaderboard_repository.dart';
import '../../../leaderboard/domain/medals.model.dart';
import '../../../leaderboard/domain/season_standing.model.dart';
import '../../../leaderboard/domain/season_window.model.dart';
import '../../../match/domain/game_type.enum.dart';
import '../../../match/domain/match_entry.model.dart';
import '../../../match/domain/match_repository.dart';
import '../../../match/presentation/cubit/game_type_filter_cubit.dart';
import '../../domain/best_streaks.model.dart';
import '../../domain/head_to_head_record.model.dart';
import '../../domain/profile_repository.dart';
import '../../domain/rating_point.model.dart';
import '../../domain/recent_played.model.dart';
import '../../domain/streak.model.dart';
import 'profile_state.dart';

export 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(
    this._leaderboardRepository,
    this._profileRepository,
    this._matchRepository,
    this._gameTypeFilterCubit,
    this.competitionId,
    this.playerId,
  ) : super(const ProfileState()) {
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
  String? _viewerPlayerId;

  Future<void> load({String? viewerPlayerId}) async {
    emit(const ProfileState());
    _viewerPlayerId = viewerPlayerId;
    try {
      final hasOpponent = viewerPlayerId != null && viewerPlayerId != playerId;
      final results = await Future.wait<Object?>([
        _leaderboardRepository.currentSeason(competitionId),
        if (hasOpponent)
          _profileRepository.headToHead(
            playerId: playerId,
            opponentId: viewerPlayerId,
          ),
      ]);
      if (isClosed) return;

      _seasonId = (results[0] as SeasonWindow).id;
      final headToHead = hasOpponent
          ? results[1] as List<HeadToHeadRecord>
          : const <HeadToHeadRecord>[];

      final gameType = _gameTypeFilterCubit.state;
      final filtered = await _loadForGameType(gameType);
      if (isClosed || gameType != _gameTypeFilterCubit.state) return;

      emit(filtered.copyWith(hasOpponent: hasOpponent, headToHead: headToHead));
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(ProfileState(status: ProfileStatus.failed, failure: failure));
    }
  }

  Future<void> selectGameTypeFilter(GameType? gameType) =>
      _gameTypeFilterCubit.select(gameType);

  Future<void> _applyGameType(GameType? gameType) async {
    if (gameType == state.selectedGameType) return;
    if (state.status != ProfileStatus.ready) return;

    try {
      final filtered = await _loadForGameType(gameType);
      if (isClosed || gameType != _gameTypeFilterCubit.state) return;

      emit(
        filtered.copyWith(
          hasOpponent: state.hasOpponent,
          headToHead: state.headToHead,
        ),
      );
    } on Failure catch (failure) {
      if (isClosed || gameType != _gameTypeFilterCubit.state) return;
      emit(state.copyWith(failure: failure));
    }
  }

  Future<ProfileState> _loadForGameType(GameType? gameType) async {
    final opponentId = _viewerPlayerId;
    final hasVersusOpponent = opponentId != null && opponentId != playerId;
    final seasonId = _seasonId;

    final results = await Future.wait<Object?>([
      _profileRepository.totalMatchesPlayed(
        playerId: playerId,
        gameType: gameType,
      ),
      _matchRepository.recentForPlayer(playerId: playerId, gameType: gameType),
      _profileRepository.bestStreaks(playerId: playerId, gameType: gameType),
      if (hasVersusOpponent)
        _matchRepository.recentBetweenPlayers(
          playerId: playerId,
          opponentId: opponentId,
          gameType: gameType,
        ),
      _leaderboardRepository.seasonHistory(
        competitionId: competitionId,
        playerId: playerId,
        gameType: gameType,
      ),
      _leaderboardRepository.medals(competitionId, gameType: gameType),
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
    var next = 3;
    final versusRecentMatches = hasVersusOpponent
        ? results[next++] as List<MatchEntry>
        : const <MatchEntry>[];
    final seasonHistory = results[next++] as List<SeasonStanding>;
    final allMedals = results[next++] as List<Medals>;

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

    final bestRating = [
      if (mine != null) mine.rating,
      for (final past in seasonHistory) past.rating,
    ].fold(0.0, (best, rating) => rating > best ? rating : best);

    return ProfileState(
      status: ProfileStatus.ready,
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
      seasonHistory: seasonHistory,
      recentMatches: recentMatches,
      versusRecentMatches: versusRecentMatches,
    );
  }

  @override
  Future<void> close() {
    _gameTypeSubscription?.cancel();
    return super.close();
  }
}
