import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/extensions/string.extension.dart';
import '../../../player/domain/player.model.dart';
import '../../domain/join_preview.model.dart';

sealed class JoinCompetitionState extends Equatable {
  const JoinCompetitionState();
}

class JoinCode extends JoinCompetitionState {
  const JoinCode({this.code = '', this.busy = false, this.failure});

  final String code;
  final bool busy;
  final Failure? failure;

  String get normalizedCode => code.normalizedJoinCode;

  bool get codeIsValid => code.isJoinCode;

  bool get canLookUp => codeIsValid && !busy;

  JoinCode copyWith({
    String? code,
    bool? busy,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return JoinCode(
      code: code ?? this.code,
      busy: busy ?? this.busy,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [code, busy, failure];
}

class JoinConfirm extends JoinCompetitionState {
  const JoinConfirm({
    required this.code,
    required this.preview,
    this.selectedClaimId,
    this.busy = false,
    this.joined,
    this.failure,
  });

  final String code;
  final JoinPreview preview;
  final String? selectedClaimId;
  final bool busy;
  final Player? joined;
  final Failure? failure;

  bool get canJoin => !busy && !preview.alreadyMember;

  JoinConfirm copyWith({
    String? selectedClaimId,
    bool clearClaim = false,
    bool? busy,
    Player? joined,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return JoinConfirm(
      code: code,
      preview: preview,
      selectedClaimId: clearClaim
          ? null
          : (selectedClaimId ?? this.selectedClaimId),
      busy: busy ?? this.busy,
      joined: joined ?? this.joined,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [
    code,
    preview,
    selectedClaimId,
    busy,
    joined,
    failure,
  ];
}
