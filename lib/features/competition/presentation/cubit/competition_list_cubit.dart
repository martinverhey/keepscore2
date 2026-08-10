import 'package:bloc/bloc.dart';

import '../../../../core/error/failure.dart';
import '../../domain/competition_repository.dart';
import 'competition_list_state.dart';

export 'competition_list_state.dart';

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
