import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/competition.model.dart';

sealed class CreateCompetitionState extends Equatable {
  const CreateCompetitionState();
}

class CreateCompetitionEditing extends CreateCompetitionState {
  const CreateCompetitionEditing({
    this.name = '',
    this.seasonLength = SeasonLength.monthly,
    this.busy = false,
    this.failure,
  });

  final String name;
  final SeasonLength seasonLength;
  final bool busy;
  final Failure? failure;

  bool get nameIsValid => name.trim().length >= 2;

  bool get canSubmit => nameIsValid && !busy;

  CreateCompetitionEditing copyWith({
    String? name,
    SeasonLength? seasonLength,
    bool? busy,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return CreateCompetitionEditing(
      name: name ?? this.name,
      seasonLength: seasonLength ?? this.seasonLength,
      busy: busy ?? this.busy,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [name, seasonLength, busy, failure];
}

class CreateCompetitionCreated extends CreateCompetitionState {
  const CreateCompetitionCreated(this.competition);

  final Competition competition;

  @override
  List<Object?> get props => [competition];
}
