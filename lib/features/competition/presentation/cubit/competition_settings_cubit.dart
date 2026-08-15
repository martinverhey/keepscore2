import 'package:bloc/bloc.dart';

import '../../../../core/error/failure.dart';
import '../../domain/competition.model.dart';
import '../../domain/competition_repository.dart';
import 'competition_settings_state.dart';

export 'competition_settings_state.dart';

class CompetitionSettingsCubit extends Cubit<CompetitionSettingsState> {
  CompetitionSettingsCubit(this._repository, this.competitionId)
    : super(const CompetitionSettingsState());

  final CompetitionRepository _repository;
  final String competitionId;

  Future<void> load() async {
    emit(const CompetitionSettingsState());
    try {
      final overview = await _repository.overview(competitionId);
      if (isClosed) return;
      emit(
        overview == null
            ? const CompetitionSettingsState(
                status: CompetitionSettingsStatus.missing,
              )
            : CompetitionSettingsState.of(overview.competition),
      );
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(
        CompetitionSettingsState(
          status: CompetitionSettingsStatus.failed,
          failure: failure,
        ),
      );
    }
  }

  void nameChanged(String value) => _edit(state.copyWith(name: value));

  void seasonLengthChanged(SeasonLength value) =>
      _edit(state.copyWith(seasonLength: value));

  void kFactorChanged(String value) => _edit(state.copyWith(kFactor: value));

  void movEnabledChanged(bool value) =>
      _edit(state.copyWith(movEnabled: value));

  void movCapChanged(String value) => _edit(state.copyWith(movCap: value));

  void allowDrawsChanged(bool value) =>
      _edit(state.copyWith(allowDraws: value));

  void _edit(CompetitionSettingsState next) =>
      emit(next.copyWith(saved: false, clearFailure: true));

  Future<void> submit() async {
    if (!state.canSubmit) return;
    emit(state.copyWith(busy: true, saved: false, clearFailure: true));
    try {
      final competition = await _repository.updateSettings(
        competitionId: competitionId,
        name: state.name,
        seasonLength: state.seasonLength,
        kFactor: state.kFactorValue!,
        movEnabled: state.movEnabled,
        movCap: state.movCapValue!,
        allowDraws: state.allowDraws,
      );
      if (isClosed) return;
      emit(CompetitionSettingsState.of(competition).copyWith(saved: true));
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(state.copyWith(busy: false, failure: failure));
    }
  }
}
