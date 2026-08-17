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
  ) : super(const ProfileVersusLoading()) {
    _gameTypeSubscription = _gameTypeFilterCubit.stream.listen(_applyGameType);
  }

  final ProfileRepository _profileRepository;
  final MatchRepository _matchRepository;
  final GameTypeFilterCubit _gameTypeFilterCubit;
  final String playerId;
  final String opponentId;

  StreamSubscription<GameType?>? _gameTypeSubscription;

  ProfileVersusReady? get _ready => switch (state) {
    ProfileVersusReady ready => ready,
    _ => null,
  };

  Future<void> load() async {
    emit(const ProfileVersusLoading());
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
        ProfileVersusReady(
          selectedGameType: gameType,
          headToHead: headToHead,
          recentMatches: recentMatches,
        ),
      );
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(ProfileVersusFailed(failure));
    }
  }

  Future<void> _applyGameType(GameType? gameType) async {
    final ready = _ready;
    if (ready == null || gameType == ready.selectedGameType) return;

    try {
      final recentMatches = await _matchRepository.recentBetweenPlayers(
        playerId: playerId,
        opponentId: opponentId,
        gameType: gameType,
      );
      if (isClosed || gameType != _gameTypeFilterCubit.state) return;
      final latest = _ready;
      if (latest != null) {
        emit(
          latest.copyWith(
            selectedGameType: gameType,
            recentMatches: recentMatches,
          ),
        );
      }
    } on Failure {
      return;
    }
  }

  @override
  Future<void> close() {
    _gameTypeSubscription?.cancel();
    return super.close();
  }
}
