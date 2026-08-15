import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../competition/domain/competition.model.dart';
import '../../domain/match_entry.model.dart';

enum MatchDetailStatus { loading, ready, missing, failed }

class MatchDetailState extends Equatable {
  const MatchDetailState({
    this.status = MatchDetailStatus.loading,
    this.match,
    this.competition,
    this.busy = false,
    this.failure,
    this.actionFailure,
  });

  final MatchDetailStatus status;
  final MatchEntry? match;
  final Competition? competition;
  final bool busy;
  final Failure? failure;
  final Failure? actionFailure;

  bool isManageableBy(String? userId) {
    final entry = match;
    final ownerId = competition?.ownerId;
    if (entry == null || ownerId == null) return false;
    return entry.isManageableBy(userId, ownerId: ownerId);
  }

  MatchDetailState copyWith({
    MatchDetailStatus? status,
    MatchEntry? match,
    Competition? competition,
    bool? busy,
    Failure? actionFailure,
    bool clearActionFailure = false,
  }) {
    return MatchDetailState(
      status: status ?? this.status,
      match: match ?? this.match,
      competition: competition ?? this.competition,
      busy: busy ?? this.busy,
      failure: failure,
      actionFailure: clearActionFailure
          ? null
          : (actionFailure ?? this.actionFailure),
    );
  }

  @override
  List<Object?> get props => [
    status,
    match,
    competition,
    busy,
    failure,
    actionFailure,
  ];
}
