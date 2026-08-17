import 'package:bloc/bloc.dart';

import '../../../../core/error/failure.dart';
import '../../domain/competition_repository.dart';
import 'competition_detail_state.dart';

export 'competition_detail_state.dart';

class CompetitionDetailCubit extends Cubit<CompetitionDetailState> {
  CompetitionDetailCubit(this._repository, this.competitionId)
    : super(const CompetitionDetailLoading());

  final CompetitionRepository _repository;
  final String competitionId;

  CompetitionDetailReady? get _ready => switch (state) {
    CompetitionDetailReady ready => ready,
    _ => null,
  };

  Future<void> load({bool silent = false}) async {
    final ready = _ready;
    if (!silent) emit(const CompetitionDetailLoading());
    try {
      final overview = await _repository.overview(competitionId);
      if (isClosed) return;
      emit(
        overview == null
            ? const CompetitionDetailMissing()
            : CompetitionDetailReady(overview),
      );
    } on Failure catch (failure) {
      if (isClosed) return;
      if (silent && ready != null) return;
      emit(CompetitionDetailFailed(failure));
    }
  }

  Future<void> refresh() => load(silent: true);
}
