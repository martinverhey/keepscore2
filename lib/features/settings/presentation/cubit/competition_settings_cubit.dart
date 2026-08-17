import 'package:bloc/bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../competition/domain/competition.model.dart';
import '../../../competition/domain/competition_repository.dart';
import 'competition_settings_state.dart';

export 'competition_settings_state.dart';

class CompetitionSettingsCubit extends Cubit<CompetitionSettingsState> {
  CompetitionSettingsCubit(this._repository, this.competitionId)
    : super(const CompetitionSettingsLoading());

  final CompetitionRepository _repository;
  final String competitionId;

  CompetitionSettingsReady? get _ready => switch (state) {
    CompetitionSettingsReady ready => ready,
    _ => null,
  };

  Future<void> load() async {
    emit(const CompetitionSettingsLoading());
    try {
      final overview = await _repository.overview(competitionId);
      if (isClosed) return;
      emit(
        overview == null
            ? const CompetitionSettingsMissing()
            : CompetitionSettingsReady.of(overview.competition),
      );
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(CompetitionSettingsFailed(failure));
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

  void _edit(
    CompetitionSettingsReady Function(CompetitionSettingsReady) apply,
  ) {
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
      emit(CompetitionSettingsReady.of(competition).copyWith(saved: true));
    } on Failure catch (failure) {
      if (isClosed) return;
      final latest = _ready;
      if (latest != null) {
        emit(latest.copyWith(busy: false, failure: failure));
      }
    }
  }
}
