import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/extensions/string_join_code.dart';
import '../../../player/domain/player.model.dart';
import '../../domain/join_preview.model.dart';

enum JoinStep { code, confirm }

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

  String get normalizedCode => code.normalizedJoinCode;

  bool get codeIsValid => normalizedCode.length == 6;

  bool get canLookUp => codeIsValid && !busy;

  bool get canJoin =>
      preview != null && !busy && !(preview?.alreadyMember ?? false);

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
      selectedClaimId: clearClaim
          ? null
          : (selectedClaimId ?? this.selectedClaimId),
      joined: joined ?? this.joined,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [
    step,
    code,
    busy,
    preview,
    selectedClaimId,
    joined,
    failure,
  ];
}
