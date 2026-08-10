import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/competition.dart';
import '../../domain/competition_repository.dart';

class CreateCompetitionState extends Equatable {
  const CreateCompetitionState({
    this.name = '',
    this.seasonLength = SeasonLength.monthly,
    this.busy = false,
    this.created,
    this.failure,
  });

  final String name;
  final SeasonLength seasonLength;
  final bool busy;
  final Competition? created;
  final Failure? failure;

  bool get nameIsValid => name.trim().length >= 2;

  bool get canSubmit => nameIsValid && !busy;

  CreateCompetitionState copyWith({
    String? name,
    SeasonLength? seasonLength,
    bool? busy,
    Competition? created,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return CreateCompetitionState(
      name: name ?? this.name,
      seasonLength: seasonLength ?? this.seasonLength,
      busy: busy ?? this.busy,
      created: created ?? this.created,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [name, seasonLength, busy, created, failure];
}

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
