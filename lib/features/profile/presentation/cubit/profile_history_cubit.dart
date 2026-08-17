import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../leaderboard/domain/leaderboard_repository.dart';
import '../../../match/domain/game_type.enum.dart';
import '../../../match/presentation/cubit/game_type_filter_cubit.dart';
import 'profile_history_state.dart';

export 'profile_history_state.dart';

class ProfileHistoryCubit extends Cubit<ProfileHistoryState> {
  ProfileHistoryCubit(
    this._repository,
    this._gameTypeFilterCubit,
    this.competitionId,
    this.playerId,
  ) : super(const ProfileHistoryLoading()) {
    _gameTypeSubscription = _gameTypeFilterCubit.stream.listen(_applyGameType);
  }

  final LeaderboardRepository _repository;
  final GameTypeFilterCubit _gameTypeFilterCubit;
  final String competitionId;
  final String playerId;

  StreamSubscription<GameType?>? _gameTypeSubscription;

  ProfileHistoryReady? get _ready => switch (state) {
    ProfileHistoryReady ready => ready,
    _ => null,
  };

  Future<void> load() async {
    emit(const ProfileHistoryLoading());
    final gameType = _gameTypeFilterCubit.state;
    try {
      final leaderboards = await _repository.history(
        competitionId: competitionId,
        playerId: playerId,
        gameType: gameType,
      );
      if (isClosed || gameType != _gameTypeFilterCubit.state) return;
      emit(
        ProfileHistoryReady(
          selectedGameType: gameType,
          leaderboards: leaderboards,
        ),
      );
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(ProfileHistoryFailed(failure));
    }
  }

  Future<void> _applyGameType(GameType? gameType) async {
    final ready = _ready;
    if (ready == null || gameType == ready.selectedGameType) return;

    try {
      final leaderboards = await _repository.history(
        competitionId: competitionId,
        playerId: playerId,
        gameType: gameType,
      );
      if (isClosed || gameType != _gameTypeFilterCubit.state) return;
      final latest = _ready;
      if (latest != null) {
        emit(
          latest.copyWith(
            selectedGameType: gameType,
            leaderboards: leaderboards,
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
