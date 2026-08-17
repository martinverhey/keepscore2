import 'package:bloc/bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../competition/domain/competition.model.dart';
import '../../../competition/domain/competition_repository.dart';
import 'configuration_state.dart';

export 'configuration_state.dart';

class ConfigurationCubit extends Cubit<ConfigurationState> {
  ConfigurationCubit(this._repository, this.competitionId)
    : super(const ConfigurationLoading());

  final CompetitionRepository _repository;
  final String competitionId;

  ConfigurationReady? get _ready => switch (state) {
    ConfigurationReady ready => ready,
    _ => null,
  };

  Future<void> load() async {
    emit(const ConfigurationLoading());
    try {
      final overview = await _repository.overview(competitionId);
      if (isClosed) return;
      emit(
        overview == null
            ? const ConfigurationMissing()
            : ConfigurationReady.of(overview.competition),
      );
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(ConfigurationFailed(failure));
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

  void _edit(ConfigurationReady Function(ConfigurationReady) apply) {
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
      emit(ConfigurationReady.of(competition).copyWith(saved: true));
    } on Failure catch (failure) {
      if (isClosed) return;
      final latest = _ready;
      if (latest != null) {
        emit(latest.copyWith(busy: false, failure: failure));
      }
    }
  }
}
