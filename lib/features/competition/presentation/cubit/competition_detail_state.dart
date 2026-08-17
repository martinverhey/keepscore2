import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/competition.model.dart';

sealed class CompetitionDetailState extends Equatable {
  const CompetitionDetailState();

  Competition? get competition => null;

  String? get myPlayerId => null;
}

class CompetitionDetailLoading extends CompetitionDetailState {
  const CompetitionDetailLoading();

  @override
  List<Object?> get props => [];
}

class CompetitionDetailMissing extends CompetitionDetailState {
  const CompetitionDetailMissing();

  @override
  List<Object?> get props => [];
}

class CompetitionDetailFailed extends CompetitionDetailState {
  const CompetitionDetailFailed(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

class CompetitionDetailReady extends CompetitionDetailState {
  const CompetitionDetailReady(this.overview);

  final CompetitionOverview overview;

  @override
  Competition get competition => overview.competition;

  @override
  String? get myPlayerId => overview.myPlayerId;

  @override
  List<Object?> get props => [overview];
}
