import 'package:bloc/bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../leaderboard/domain/leaderboard_repository.dart';
import 'profile_history_state.dart';

export 'profile_history_state.dart';

class ProfileHistoryCubit extends Cubit<ProfileHistoryState> {
  ProfileHistoryCubit(this._repository, this.competitionId, this.playerId)
    : super(const ProfileHistoryLoading());

  final LeaderboardRepository _repository;
  final String competitionId;
  final String playerId;

  Future<void> load() async {
    emit(const ProfileHistoryLoading());
    try {
      final leaderboards = await _repository.history(
        competitionId: competitionId,
        playerId: playerId,
      );
      if (isClosed) return;
      emit(ProfileHistoryReady(leaderboards: leaderboards));
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(ProfileHistoryFailed(failure));
    }
  }
}
