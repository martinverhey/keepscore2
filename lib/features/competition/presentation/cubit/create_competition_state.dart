import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/competition.model.dart';

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
