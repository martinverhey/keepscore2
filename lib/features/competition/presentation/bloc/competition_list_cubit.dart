import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/competition.dart';
import '../../domain/competition_repository.dart';

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

class CompetitionListCubit extends Cubit<CompetitionListState> {
  CompetitionListCubit(this._repository) : super(const CompetitionListState());

  final CompetitionRepository _repository;

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      emit(const CompetitionListState());
    }
    try {
      final competitions = await _repository.myCompetitions();
      if (isClosed) return;
      emit(CompetitionListState(
        status: CompetitionListStatus.ready,
        competitions: competitions,
      ));
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(CompetitionListState(
        status: CompetitionListStatus.failed,
        competitions: silent ? state.competitions : const [],
        failure: failure,
      ));
    }
  }

  Future<void> refresh() => load(silent: true);
}
