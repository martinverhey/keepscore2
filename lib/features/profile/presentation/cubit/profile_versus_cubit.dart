import 'package:bloc/bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../match/domain/match_repository.dart';
import '../../domain/profile_repository.dart';
import 'profile_versus_state.dart';

export 'profile_versus_state.dart';

class ProfileVersusCubit extends Cubit<ProfileVersusState> {
  ProfileVersusCubit(
    this._profileRepository,
    this._matchRepository,
    this.playerId,
    this.opponentId,
  ) : super(const ProfileVersusLoading());

  final ProfileRepository _profileRepository;
  final MatchRepository _matchRepository;
  final String playerId;
  final String opponentId;

  Future<void> load() async {
    emit(const ProfileVersusLoading());
    try {
      final headToHeadFuture = _profileRepository.headToHead(
        playerId: playerId,
        opponentId: opponentId,
      );
      final recentMatchesFuture = _matchRepository.recentBetweenPlayers(
        playerId: playerId,
        opponentId: opponentId,
      );

      final headToHead = await headToHeadFuture;
      final recentMatches = await recentMatchesFuture;
      if (isClosed) return;
      emit(
        ProfileVersusReady(
          headToHead: headToHead,
          recentMatches: recentMatches,
        ),
      );
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(ProfileVersusFailed(failure));
    }
  }
}
