import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/competition.dart';
import '../../domain/competition_repository.dart';

enum CompetitionDetailStatus {
  loading,
  ready,

  missing,
  failed,
}

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

class CompetitionDetailCubit extends Cubit<CompetitionDetailState> {
  CompetitionDetailCubit(this._repository, this.competitionId)
      : super(const CompetitionDetailState());

  final CompetitionRepository _repository;
  final String competitionId;

  Future<void> load({bool silent = false}) async {
    if (!silent) emit(const CompetitionDetailState());
    try {
      final overview = await _repository.overview(competitionId);
      if (isClosed) return;
      emit(CompetitionDetailState(
        status: overview == null
            ? CompetitionDetailStatus.missing
            : CompetitionDetailStatus.ready,
        overview: overview,
      ));
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(CompetitionDetailState(
        status: CompetitionDetailStatus.failed,
        overview: silent ? state.overview : null,
        failure: failure,
      ));
    }
  }

  Future<void> refresh() => load(silent: true);
}
