import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/competition.dart';

enum CompetitionListStatus { loading, ready, failed }

class CompetitionListState extends Equatable {
  const CompetitionListState({
    this.status = CompetitionListStatus.loading,
    this.competitions = const [],
    this.busy = false,
    this.failure,
    this.actionFailure,
  });

  final CompetitionListStatus status;
  final List<CompetitionOverview> competitions;
  final bool busy;
  final Failure? failure;
  final Failure? actionFailure;

  bool get isEmpty =>
      status == CompetitionListStatus.ready && competitions.isEmpty;

  CompetitionListState copyWith({
    CompetitionListStatus? status,
    List<CompetitionOverview>? competitions,
    bool? busy,
    Failure? failure,
    Failure? actionFailure,
    bool clearActionFailure = false,
  }) {
    return CompetitionListState(
      status: status ?? this.status,
      competitions: competitions ?? this.competitions,
      busy: busy ?? this.busy,
      failure: failure ?? this.failure,
      actionFailure: clearActionFailure
          ? null
          : (actionFailure ?? this.actionFailure),
    );
  }

  @override
  List<Object?> get props => [
    status,
    competitions,
    busy,
    failure,
    actionFailure,
  ];
}
