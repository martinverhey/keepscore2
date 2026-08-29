import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../competition/domain/competition.model.dart';
import '../../domain/match_entry.model.dart';

sealed class MatchDetailState extends Equatable {
  const MatchDetailState();
}

class MatchDetailLoading extends MatchDetailState {
  const MatchDetailLoading();

  @override
  List<Object?> get props => [];
}

class MatchDetailMissing extends MatchDetailState {
  const MatchDetailMissing();

  @override
  List<Object?> get props => [];
}

class MatchDetailFailed extends MatchDetailState {
  const MatchDetailFailed(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

class MatchDetailReady extends MatchDetailState {
  const MatchDetailReady({
    required this.match,
    this.competition,
    this.createdByName,
    this.busy = false,
    this.actionFailure,
  });

  final MatchEntry match;
  final Competition? competition;
  final String? createdByName;
  final bool busy;
  final Failure? actionFailure;

  bool isManageableBy(String? userId) {
    final ownerId = competition?.ownerId;
    if (ownerId == null) return false;
    return match.isManageableBy(userId, ownerId: ownerId);
  }

  MatchDetailReady copyWith({
    MatchEntry? match,
    Competition? competition,
    String? createdByName,
    bool? busy,
    Failure? actionFailure,
    bool clearActionFailure = false,
  }) {
    return MatchDetailReady(
      match: match ?? this.match,
      competition: competition ?? this.competition,
      createdByName: createdByName ?? this.createdByName,
      busy: busy ?? this.busy,
      actionFailure: clearActionFailure
          ? null
          : (actionFailure ?? this.actionFailure),
    );
  }

  @override
  List<Object?> get props => [
    match,
    competition,
    createdByName,
    busy,
    actionFailure,
  ];
}
