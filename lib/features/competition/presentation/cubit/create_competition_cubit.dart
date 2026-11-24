import 'package:bloc/bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/extensions/double.extension.dart';
import '../../../match/domain/elo_settings.model.dart';
import '../../domain/competition.model.dart';
import '../../domain/competition_repository.dart';
import 'create_competition_state.dart';

export 'create_competition_state.dart';

class CreateCompetitionCubit extends Cubit<CreateCompetitionState> {
  static const _defaults = EloSettings();

  CreateCompetitionCubit(this._repository)
    : super(
        CreateCompetitionEditing(
          kFactor: '${_defaults.kFactor}',
          movEnabled: _defaults.movEnabled,
          movCap: _defaults.movCap.inputLabel,
          shutoutBonus: _defaults.shutoutBonus,
          shutoutMultiplier: _defaults.shutoutMultiplier.inputLabel,
        ),
      );

  final CompetitionRepository _repository;

  CreateCompetitionEditing? get _editing => switch (state) {
    CreateCompetitionEditing editing => editing,
    _ => null,
  };

  void nameChanged(String value) {
    final editing = _editing;
    if (editing == null) return;
    emit(editing.copyWith(name: value, clearFailure: true));
  }

  void seasonLengthChanged(SeasonLength value) {
    final editing = _editing;
    if (editing == null) return;
    emit(editing.copyWith(seasonLength: value, clearFailure: true));
  }

  void kFactorChanged(String value) {
    final editing = _editing;
    if (editing == null) return;
    emit(editing.copyWith(kFactor: value, clearFailure: true));
  }

  void movEnabledChanged(bool value) {
    final editing = _editing;
    if (editing == null) return;
    emit(editing.copyWith(movEnabled: value, clearFailure: true));
  }

  void movCapChanged(String value) {
    final editing = _editing;
    if (editing == null) return;
    emit(editing.copyWith(movCap: value, clearFailure: true));
  }

  void shutoutBonusChanged(bool value) {
    final editing = _editing;
    if (editing == null) return;
    emit(editing.copyWith(shutoutBonus: value, clearFailure: true));
  }

  void shutoutMultiplierChanged(String value) {
    final editing = _editing;
    if (editing == null) return;
    emit(editing.copyWith(shutoutMultiplier: value, clearFailure: true));
  }

  Future<void> submit() async {
    final editing = _editing;
    if (editing == null || !editing.canSubmit) return;
    emit(editing.copyWith(busy: true, clearFailure: true));
    try {
      final competition = await _repository.create(
        name: editing.name,
        seasonLength: editing.seasonLength,
        kFactor: editing.kFactorValue!,
        movEnabled: editing.movEnabled,
        movCap: editing.movCapValue!,
        shutoutBonus: editing.shutoutBonus,
        shutoutMultiplier: editing.shutoutMultiplierValue!,
      );
      if (isClosed) return;
      emit(CreateCompetitionCreated(competition));
    } on Failure catch (failure) {
      if (isClosed) return;
      final latest = _editing;
      if (latest != null) {
        emit(latest.copyWith(busy: false, failure: failure));
      }
    }
  }
}
