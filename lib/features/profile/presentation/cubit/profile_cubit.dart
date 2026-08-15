import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../leaderboard/domain/leaderboard.model.dart';
import '../../../leaderboard/domain/leaderboard_repository.dart';
import '../../../match/domain/game_type.enum.dart';
import '../../../match/domain/match_repository.dart';
import '../../../match/presentation/cubit/game_type_filter_cubit.dart';
import '../../domain/head_to_head_record.model.dart';
import '../../domain/profile_repository.dart';
import '../../domain/rating_point.model.dart';
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

  Future<void> load({String? viewerPlayerId}) async {
    emit(const ProfileState());
    try {
      final season = await _leaderboardRepository.currentSeason(competitionId);
      _seasonId = season.id;
      if (isClosed) return;

      var headToHead = const <HeadToHeadRecord>[];
      if (viewerPlayerId != null && viewerPlayerId != playerId) {
        headToHead = await _profileRepository.headToHead(
          playerId: playerId,
          opponentId: viewerPlayerId,
        );
        if (isClosed) return;
      }

      final filtered = await _loadForGameType(_gameTypeFilterCubit.state);
      if (isClosed) return;

      emit(filtered.copyWith(headToHead: headToHead));
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
      if (isClosed) return;

      emit(filtered.copyWith(headToHead: state.headToHead));
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(state.copyWith(failure: failure));
    }
  }

  Future<ProfileState> _loadForGameType(GameType? gameType) async {
    final totalPlayed = await _profileRepository.totalMatchesPlayed(
      playerId: playerId,
      gameType: gameType,
    );
    final recentMatches = await _matchRepository.recentForPlayer(
      playerId: playerId,
      gameType: gameType,
    );
    final seasonHistory = await _leaderboardRepository.seasonHistory(
      competitionId: competitionId,
      playerId: playerId,
      gameType: gameType,
    );

    Leaderboard? mine;
    var playerCount = 0;
    var history = const <RatingPoint>[];
    var streak = const Streak.none();

    if (_seasonId != null) {
      final leaderboards = await _leaderboardRepository.leaderboards(
        competitionId: competitionId,
        seasonId: _seasonId,
        gameType: gameType,
      );
      history = await _profileRepository.ratingHistory(
        seasonId: _seasonId!,
        playerId: playerId,
        gameType: gameType,
      );
      streak = await _profileRepository.currentStreak(
        seasonId: _seasonId!,
        playerId: playerId,
        gameType: gameType,
      );

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
      bestRating: bestRating,
      playerCount: playerCount,
      history: history,
      totalPlayed: totalPlayed,
      streak: streak,
      seasonHistory: seasonHistory,
      recentMatches: recentMatches,
    );
  }

  @override
  Future<void> close() {
    _gameTypeSubscription?.cancel();
    return super.close();
  }
}
