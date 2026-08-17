import 'package:bloc/bloc.dart';

import '../../../../core/error/failure.dart';
import '../../domain/competition.model.dart';
import '../../domain/competition_repository.dart';
import 'create_competition_state.dart';

export 'create_competition_state.dart';

class CreateCompetitionCubit extends Cubit<CreateCompetitionState> {
  CreateCompetitionCubit(this._repository)
    : super(const CreateCompetitionEditing());

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

  Future<void> submit() async {
    final editing = _editing;
    if (editing == null || !editing.canSubmit) return;
    emit(editing.copyWith(busy: true, clearFailure: true));
    try {
      final competition = await _repository.create(
        name: editing.name,
        seasonLength: editing.seasonLength,
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
