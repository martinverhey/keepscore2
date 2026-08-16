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
  ) : super(const ProfileHistoryState()) {
    _gameTypeSubscription = _gameTypeFilterCubit.stream.listen(_applyGameType);
  }

  final LeaderboardRepository _repository;
  final GameTypeFilterCubit _gameTypeFilterCubit;
  final String competitionId;
  final String playerId;

  StreamSubscription<GameType?>? _gameTypeSubscription;

  Future<void> load() async {
    emit(const ProfileHistoryState());
    final gameType = _gameTypeFilterCubit.state;
    try {
      final leaderboards = await _repository.history(
        competitionId: competitionId,
        playerId: playerId,
        gameType: gameType,
      );
      if (isClosed || gameType != _gameTypeFilterCubit.state) return;
      emit(
        ProfileHistoryState(
          status: ProfileHistoryStatus.ready,
          selectedGameType: gameType,
          leaderboards: leaderboards,
        ),
      );
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(
        ProfileHistoryState(
          status: ProfileHistoryStatus.failed,
          failure: failure,
        ),
      );
    }
  }

  Future<void> _applyGameType(GameType? gameType) async {
    if (gameType == state.selectedGameType) return;
    if (state.status != ProfileHistoryStatus.ready) return;

    try {
      final leaderboards = await _repository.history(
        competitionId: competitionId,
        playerId: playerId,
        gameType: gameType,
      );
      if (isClosed || gameType != _gameTypeFilterCubit.state) return;
      emit(
        state.copyWith(selectedGameType: gameType, leaderboards: leaderboards),
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
