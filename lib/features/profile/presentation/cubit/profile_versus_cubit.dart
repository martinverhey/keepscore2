import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../match/domain/game_type.enum.dart';
import '../../../match/domain/match_repository.dart';
import '../../../match/presentation/cubit/game_type_filter_cubit.dart';
import '../../domain/profile_repository.dart';
import 'profile_versus_state.dart';

export 'profile_versus_state.dart';

class ProfileVersusCubit extends Cubit<ProfileVersusState> {
  ProfileVersusCubit(
    this._profileRepository,
    this._matchRepository,
    this._gameTypeFilterCubit,
    this.playerId,
    this.opponentId,
  ) : super(const ProfileVersusState()) {
    _gameTypeSubscription = _gameTypeFilterCubit.stream.listen(_applyGameType);
  }

  final ProfileRepository _profileRepository;
  final MatchRepository _matchRepository;
  final GameTypeFilterCubit _gameTypeFilterCubit;
  final String playerId;
  final String opponentId;

  StreamSubscription<GameType?>? _gameTypeSubscription;

  Future<void> load() async {
    emit(const ProfileVersusState());
    final gameType = _gameTypeFilterCubit.state;
    try {
      final headToHeadFuture = _profileRepository.headToHead(
        playerId: playerId,
        opponentId: opponentId,
      );
      final recentMatchesFuture = _matchRepository.recentBetweenPlayers(
        playerId: playerId,
        opponentId: opponentId,
        gameType: gameType,
      );

      final headToHead = await headToHeadFuture;
      final recentMatches = await recentMatchesFuture;
      if (isClosed || gameType != _gameTypeFilterCubit.state) return;
      emit(
        ProfileVersusState(
          status: ProfileVersusStatus.ready,
          selectedGameType: gameType,
          headToHead: headToHead,
          recentMatches: recentMatches,
        ),
      );
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(
        ProfileVersusState(status: ProfileVersusStatus.failed, failure: failure),
      );
    }
  }

  Future<void> _applyGameType(GameType? gameType) async {
    if (gameType == state.selectedGameType) return;
    if (state.status != ProfileVersusStatus.ready) return;

    try {
      final recentMatches = await _matchRepository.recentBetweenPlayers(
        playerId: playerId,
        opponentId: opponentId,
        gameType: gameType,
      );
      if (isClosed || gameType != _gameTypeFilterCubit.state) return;
      emit(
        state.copyWith(selectedGameType: gameType, recentMatches: recentMatches),
      );
    } on Failure catch (failure) {
      if (isClosed || gameType != _gameTypeFilterCubit.state) return;
      emit(state.copyWith(failure: failure));
    }
  }

  @override
  Future<void> close() {
    _gameTypeSubscription?.cancel();
    return super.close();
  }
}
