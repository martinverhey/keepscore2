import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/competition.dart';

enum CompetitionListStatus { loading, ready, failed }

class CompetitionListState extends Equatable {
  const CompetitionListState({
    this.status = CompetitionListStatus.loading,
    this.competitions = const [],
    this.failure,
  });

  final CompetitionListStatus status;
  final List<CompetitionOverview> competitions;
  final Failure? failure;

  bool get isEmpty =>
      status == CompetitionListStatus.ready && competitions.isEmpty;

  @override
  List<Object?> get props => [status, competitions, failure];
}
