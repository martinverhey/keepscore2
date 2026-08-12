import 'package:bloc/bloc.dart';

import '../../../../core/error/failure.dart';
import '../../domain/competition.dart';
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
      emit(
        CompetitionListState(
          status: CompetitionListStatus.ready,
          competitions: competitions,
        ),
      );
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(
        CompetitionListState(
          status: CompetitionListStatus.failed,
          competitions: silent ? state.competitions : const [],
          failure: failure,
        ),
      );
    }
  }

  Future<void> refresh() => load(silent: true);

  Future<bool> rename(String competitionId, String name) => _mutate(() async {
    final overview = _find(competitionId);
    if (overview == null) return;
    final competition = overview.competition;
    await _repository.updateSettings(
      competitionId: competitionId,
      name: name,
      seasonLength: competition.seasonLength,
      kFactor: competition.kFactor,
      movEnabled: competition.movEnabled,
      movCap: competition.movCap,
      allowDraws: competition.allowDraws,
    );
  });

  Future<bool> leave(String competitionId) =>
      _mutate(() => _repository.leave(competitionId));

  Future<bool> delete(String competitionId) =>
      _mutate(() => _repository.delete(competitionId));

  CompetitionOverview? _find(String competitionId) {
    for (final overview in state.competitions) {
      if (overview.id == competitionId) return overview;
    }
    return null;
  }

  Future<bool> _mutate(Future<void> Function() action) async {
    if (state.busy) return false;
    emit(state.copyWith(busy: true, clearActionFailure: true));
    try {
      await action();
      if (isClosed) return true;
      emit(state.copyWith(busy: false));
      await refresh();
      return true;
    } on Failure catch (failure) {
      if (isClosed) return false;
      emit(state.copyWith(busy: false, actionFailure: failure));
      return false;
    }
  }
}
