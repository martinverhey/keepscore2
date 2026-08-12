import 'package:bloc/bloc.dart';

import '../../../../core/error/failure.dart';
import '../../domain/competition_repository.dart';
import 'join_competition_state.dart';

export 'join_competition_state.dart';

class JoinCompetitionCubit extends Cubit<JoinCompetitionState> {
  JoinCompetitionCubit(this._repository) : super(const JoinCompetitionState());

  final CompetitionRepository _repository;

  void codeChanged(String value) =>
      emit(state.copyWith(code: value, clearFailure: true));

  void claimSelected(String? playerId) {
    if (playerId == null || playerId == state.selectedClaimId) {
      emit(state.copyWith(clearClaim: true, clearFailure: true));
    } else {
      emit(state.copyWith(selectedClaimId: playerId, clearFailure: true));
    }
  }

  void back() => emit(
    state.copyWith(step: JoinStep.code, clearClaim: true, clearFailure: true),
  );

  Future<void> lookUp() async {
    if (!state.canLookUp) return;
    emit(state.copyWith(busy: true, clearFailure: true));
    try {
      final preview = await _repository.preview(state.code);
      if (isClosed) return;
      emit(
        state.copyWith(
          busy: false,
          preview: preview,
          step: JoinStep.confirm,
          clearClaim: true,
        ),
      );
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(state.copyWith(busy: false, failure: failure));
    }
  }

  Future<void> join({String? displayName}) async {
    if (!state.canJoin) return;
    emit(state.copyWith(busy: true, clearFailure: true));
    try {
      final player = await _repository.join(
        joinCode: state.code,
        claimPlayerId: state.selectedClaimId,
        displayName: displayName,
      );
      if (isClosed) return;
      emit(state.copyWith(busy: false, joined: player));
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(state.copyWith(busy: false, failure: failure));
    }
  }
}
