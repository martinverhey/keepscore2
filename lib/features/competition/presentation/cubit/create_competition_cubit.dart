import 'package:bloc/bloc.dart';

import '../../../../core/error/failure.dart';
import '../../domain/competition.dart';
import '../../domain/competition_repository.dart';
import 'create_competition_state.dart';

export 'create_competition_state.dart';

class CreateCompetitionCubit extends Cubit<CreateCompetitionState> {
  CreateCompetitionCubit(this._repository)
    : super(const CreateCompetitionState());

  final CompetitionRepository _repository;

  void nameChanged(String value) =>
      emit(state.copyWith(name: value, clearFailure: true));

  void seasonLengthChanged(SeasonLength value) =>
      emit(state.copyWith(seasonLength: value, clearFailure: true));

  Future<void> submit() async {
    if (!state.canSubmit) return;
    emit(state.copyWith(busy: true, clearFailure: true));
    try {
      final competition = await _repository.create(
        name: state.name,
        seasonLength: state.seasonLength,
      );
      if (isClosed) return;
      emit(state.copyWith(busy: false, created: competition));
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(state.copyWith(busy: false, failure: failure));
    }
  }
}
