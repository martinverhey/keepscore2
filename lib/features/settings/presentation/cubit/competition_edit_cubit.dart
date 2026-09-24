import 'package:bloc/bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../competition/domain/competition.model.dart';
import '../../../competition/domain/competition_repository.dart';
import 'competition_edit_state.dart';

export 'competition_edit_state.dart';

class CompetitionEditCubit extends Cubit<CompetitionEditState> {
  CompetitionEditCubit(this._repository, this.competitionId)
    : super(const CompetitionEditLoading());

  final CompetitionRepository _repository;
  final String competitionId;

  CompetitionEditReady? get _ready => switch (state) {
    CompetitionEditReady ready => ready,
    _ => null,
  };

  Future<void> load() async {
    emit(const CompetitionEditLoading());
    try {
      final overview = await _repository.overview(competitionId);
      if (isClosed) return;
      emit(
        overview == null
            ? const CompetitionEditMissing()
            : CompetitionEditReady.of(overview.competition),
      );
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(CompetitionEditFailed(failure));
    }
  }

  void nameChanged(String value) =>
      _edit((ready) => ready.copyWith(name: value));

  void seasonLengthChanged(SeasonLength value) =>
      _edit((ready) => ready.copyWith(seasonLength: value));

  void kFactorChanged(String value) =>
      _edit((ready) => ready.copyWith(kFactor: value));

  void movEnabledChanged(bool value) =>
      _edit((ready) => ready.copyWith(movEnabled: value));

  void movCapChanged(String value) =>
      _edit((ready) => ready.copyWith(movCap: value));

  void allowDrawsChanged(bool value) =>
      _edit((ready) => ready.copyWith(allowDraws: value));

  void _edit(CompetitionEditReady Function(CompetitionEditReady) apply) {
    final ready = _ready;
    if (ready == null) return;
    emit(apply(ready).copyWith(saved: false, clearFailure: true));
  }

  Future<void> submit() async {
    final ready = _ready;
    if (ready == null || !ready.canSubmit) return;
    emit(ready.copyWith(busy: true, saved: false, clearFailure: true));
    try {
      final competition = await _repository.updateSettings(
        competitionId: competitionId,
        name: ready.name,
        seasonLength: ready.seasonLength,
        kFactor: ready.kFactorValue!,
        movEnabled: ready.movEnabled,
        movCap: ready.movCapValue!,
        allowDraws: ready.allowDraws,
      );
      if (isClosed) return;
      emit(CompetitionEditReady.of(competition).copyWith(saved: true));
    } on Failure catch (failure) {
      if (isClosed) return;
      final latest = _ready;
      if (latest != null) {
        emit(latest.copyWith(busy: false, failure: failure));
      }
    }
  }
}
