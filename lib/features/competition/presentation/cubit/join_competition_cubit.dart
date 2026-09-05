import 'package:bloc/bloc.dart';

import '../../../../core/error/failure.dart';
import '../../domain/competition_repository.dart';
import 'join_competition_state.dart';

export 'join_competition_state.dart';

class JoinCompetitionCubit extends Cubit<JoinCompetitionState> {
  JoinCompetitionCubit(this._repository) : super(const JoinCode());

  final CompetitionRepository _repository;

  JoinCode? get _code => switch (state) {
    JoinCode code => code,
    _ => null,
  };

  JoinConfirm? get _confirm => switch (state) {
    JoinConfirm confirm => confirm,
    _ => null,
  };

  void codeChanged(String value) {
    final code = _code;
    if (code == null) return;
    emit(code.copyWith(code: value, clearFailure: true));
  }

  void claimSelected(String? playerId) {
    final confirm = _confirm;
    if (confirm == null) return;
    if (playerId == null || playerId == confirm.selectedClaimId) {
      emit(confirm.copyWith(clearClaim: true, clearFailure: true));
    } else {
      emit(confirm.copyWith(selectedClaimId: playerId, clearFailure: true));
    }
  }

  void back() {
    final confirm = _confirm;
    if (confirm == null) return;
    emit(JoinCode(code: confirm.code));
  }

  Future<void> lookUpCode(String code) {
    codeChanged(code);
    return lookUp();
  }

  Future<void> lookUp() async {
    final code = _code;
    if (code == null || !code.canLookUp) return;
    emit(code.copyWith(busy: true, clearFailure: true));
    try {
      final preview = await _repository.preview(code.code);
      if (isClosed) return;
      emit(JoinConfirm(code: code.code, preview: preview));
    } on Failure catch (failure) {
      if (isClosed) return;
      final latest = _code;
      if (latest != null) emit(latest.copyWith(busy: false, failure: failure));
    }
  }

  Future<void> join({String? displayName}) async {
    final confirm = _confirm;
    if (confirm == null || !confirm.canJoin) return;
    emit(confirm.copyWith(busy: true, clearFailure: true));
    try {
      final player = await _repository.join(
        joinCode: confirm.code,
        claimPlayerId: confirm.selectedClaimId,
        displayName: displayName,
      );
      if (isClosed) return;
      final latest = _confirm;
      if (latest != null) emit(latest.copyWith(busy: false, joined: player));
    } on Failure catch (failure) {
      if (isClosed) return;
      final latest = _confirm;
      if (latest != null) {
        emit(latest.copyWith(busy: false, failure: failure));
      }
    }
  }
}
