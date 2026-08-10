import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../player/domain/player.dart';
import '../../domain/competition_repository.dart';
import '../../domain/join_preview.dart';

enum JoinStep {
  code,

  confirm,
}

class JoinCompetitionState extends Equatable {
  const JoinCompetitionState({
    this.step = JoinStep.code,
    this.code = '',
    this.busy = false,
    this.preview,
    this.selectedClaimId,
    this.joined,
    this.failure,
  });

  final JoinStep step;
  final String code;
  final bool busy;
  final JoinPreview? preview;
  final String? selectedClaimId;
  final Player? joined;
  final Failure? failure;

  String get normalizedCode =>
      code.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();

  bool get codeIsValid => normalizedCode.length == 6;

  bool get canLookUp => codeIsValid && !busy;

  bool get canJoin => preview != null && !busy && !(preview?.alreadyMember ?? false);

  JoinCompetitionState copyWith({
    JoinStep? step,
    String? code,
    bool? busy,
    JoinPreview? preview,
    String? selectedClaimId,
    bool clearClaim = false,
    Player? joined,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return JoinCompetitionState(
      step: step ?? this.step,
      code: code ?? this.code,
      busy: busy ?? this.busy,
      preview: preview ?? this.preview,
      selectedClaimId: clearClaim ? null : (selectedClaimId ?? this.selectedClaimId),
      joined: joined ?? this.joined,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props =>
      [step, code, busy, preview, selectedClaimId, joined, failure];
}

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

  void back() => emit(state.copyWith(
        step: JoinStep.code,
        clearClaim: true,
        clearFailure: true,
      ));

  Future<void> lookUp() async {
    if (!state.canLookUp) return;
    emit(state.copyWith(busy: true, clearFailure: true));
    try {
      final preview = await _repository.preview(state.code);
      if (isClosed) return;
      emit(state.copyWith(
        busy: false,
        preview: preview,
        step: JoinStep.confirm,
        clearClaim: true,
      ));
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(state.copyWith(busy: false, failure: failure));
    }
  }

  Future<void> join() async {
    if (!state.canJoin) return;
    emit(state.copyWith(busy: true, clearFailure: true));
    try {
      final player = await _repository.join(
        joinCode: state.code,
        claimPlayerId: state.selectedClaimId,
      );
      if (isClosed) return;
      emit(state.copyWith(busy: false, joined: player));
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(state.copyWith(busy: false, failure: failure));
    }
  }
}
