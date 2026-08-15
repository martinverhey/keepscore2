import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/competition.model.dart';

enum CompetitionDetailStatus { loading, ready, missing, failed }

class CompetitionDetailState extends Equatable {
  const CompetitionDetailState({
    this.status = CompetitionDetailStatus.loading,
    this.overview,
    this.failure,
  });

  final CompetitionDetailStatus status;
  final CompetitionOverview? overview;
  final Failure? failure;

  Competition? get competition => overview?.competition;

  String? get myPlayerId => overview?.myPlayerId;

  @override
  List<Object?> get props => [status, overview, failure];
}
