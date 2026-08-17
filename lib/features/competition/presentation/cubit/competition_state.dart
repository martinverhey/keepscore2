import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/competition.model.dart';

sealed class CompetitionState extends Equatable {
  const CompetitionState();

  Competition? get competition => null;

  String? get myPlayerId => null;
}

class CompetitionLoading extends CompetitionState {
  const CompetitionLoading();

  @override
  List<Object?> get props => [];
}

class CompetitionMissing extends CompetitionState {
  const CompetitionMissing();

  @override
  List<Object?> get props => [];
}

class CompetitionFailed extends CompetitionState {
  const CompetitionFailed(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

class CompetitionReady extends CompetitionState {
  const CompetitionReady(this.overview);

  final CompetitionOverview overview;

  @override
  Competition get competition => overview.competition;

  @override
  String? get myPlayerId => overview.myPlayerId;

  @override
  List<Object?> get props => [overview];
}
