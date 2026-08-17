import 'package:bloc/bloc.dart';

import '../../../../core/error/failure.dart';
import '../../domain/competition_repository.dart';
import 'competition_state.dart';

export 'competition_state.dart';

class CompetitionCubit extends Cubit<CompetitionState> {
  CompetitionCubit(this._repository, this.competitionId)
    : super(const CompetitionLoading());

  final CompetitionRepository _repository;
  final String competitionId;

  CompetitionReady? get _ready => switch (state) {
    CompetitionReady ready => ready,
    _ => null,
  };

  Future<void> load({bool silent = false}) async {
    final ready = _ready;
    if (!silent) emit(const CompetitionLoading());
    try {
      final overview = await _repository.overview(competitionId);
      if (isClosed) return;
      emit(
        overview == null
            ? const CompetitionMissing()
            : CompetitionReady(overview),
      );
    } on Failure catch (failure) {
      if (isClosed) return;
      if (silent && ready != null) return;
      emit(CompetitionFailed(failure));
    }
  }

  Future<void> refresh() => load(silent: true);
}
