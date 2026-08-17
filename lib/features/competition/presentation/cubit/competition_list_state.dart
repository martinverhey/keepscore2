import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/competition.model.dart';

sealed class CompetitionListState extends Equatable {
  const CompetitionListState();
}

class CompetitionListLoading extends CompetitionListState {
  const CompetitionListLoading();

  @override
  List<Object?> get props => [];
}

class CompetitionListFailed extends CompetitionListState {
  const CompetitionListFailed(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

class CompetitionListReady extends CompetitionListState {
  const CompetitionListReady({
    this.competitions = const [],
    this.busy = false,
    this.actionFailure,
  });

  final List<CompetitionOverview> competitions;
  final bool busy;
  final Failure? actionFailure;

  bool get isEmpty => competitions.isEmpty;

  CompetitionListReady copyWith({
    List<CompetitionOverview>? competitions,
    bool? busy,
    Failure? actionFailure,
    bool clearActionFailure = false,
  }) {
    return CompetitionListReady(
      competitions: competitions ?? this.competitions,
      busy: busy ?? this.busy,
      actionFailure: clearActionFailure
          ? null
          : (actionFailure ?? this.actionFailure),
    );
  }

  @override
  List<Object?> get props => [competitions, busy, actionFailure];
}
