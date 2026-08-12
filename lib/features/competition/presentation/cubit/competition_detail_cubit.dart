import 'package:bloc/bloc.dart';

import '../../../../core/error/failure.dart';
import '../../domain/competition_repository.dart';
import 'competition_detail_state.dart';

export 'competition_detail_state.dart';

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
      emit(
        CompetitionDetailState(
          status: overview == null
              ? CompetitionDetailStatus.missing
              : CompetitionDetailStatus.ready,
          overview: overview,
        ),
      );
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(
        CompetitionDetailState(
          status: CompetitionDetailStatus.failed,
          overview: silent ? state.overview : null,
          failure: failure,
        ),
      );
    }
  }

  Future<void> refresh() => load(silent: true);
}
