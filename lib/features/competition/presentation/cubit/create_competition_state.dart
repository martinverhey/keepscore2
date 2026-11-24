import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/extensions/string.extension.dart';
import '../../../match/domain/elo_settings.model.dart';
import '../../domain/competition.model.dart';

sealed class CreateCompetitionState extends Equatable {
  const CreateCompetitionState();
}

class CreateCompetitionEditing extends CreateCompetitionState {
  const CreateCompetitionEditing({
    this.name = '',
    this.seasonLength = SeasonLength.quarterly,
    required this.kFactor,
    this.movEnabled = true,
    required this.movCap,
    this.shutoutBonus = true,
    required this.shutoutMultiplier,
    this.busy = false,
    this.failure,
  });

  final String name;
  final SeasonLength seasonLength;
  final String kFactor;
  final bool movEnabled;
  final String movCap;
  final bool shutoutBonus;
  final String shutoutMultiplier;
  final bool busy;
  final Failure? failure;

  bool get nameIsValid => name.trim().length >= 2;

  int? get kFactorValue => kFactor.wholeNumberValue;

  bool get kFactorIsValid => EloSettings.kFactorIsValid(kFactorValue);

  double? get movCapValue => movCap.decimalValue;

  bool get movCapIsValid => EloSettings.movCapIsValid(movCapValue);

  double? get shutoutMultiplierValue => shutoutMultiplier.decimalValue;

  bool get shutoutMultiplierIsValid =>
      EloSettings.shutoutMultiplierIsValid(shutoutMultiplierValue);

  bool get canSubmit =>
      nameIsValid &&
      kFactorIsValid &&
      movCapIsValid &&
      shutoutMultiplierIsValid &&
      !busy;

  CreateCompetitionEditing copyWith({
    String? name,
    SeasonLength? seasonLength,
    String? kFactor,
    bool? movEnabled,
    String? movCap,
    bool? shutoutBonus,
    String? shutoutMultiplier,
    bool? busy,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return CreateCompetitionEditing(
      name: name ?? this.name,
      seasonLength: seasonLength ?? this.seasonLength,
      kFactor: kFactor ?? this.kFactor,
      movEnabled: movEnabled ?? this.movEnabled,
      movCap: movCap ?? this.movCap,
      shutoutBonus: shutoutBonus ?? this.shutoutBonus,
      shutoutMultiplier: shutoutMultiplier ?? this.shutoutMultiplier,
      busy: busy ?? this.busy,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [
    name,
    seasonLength,
    kFactor,
    movEnabled,
    movCap,
    shutoutBonus,
    shutoutMultiplier,
    busy,
    failure,
  ];
}

class CreateCompetitionCreated extends CreateCompetitionState {
  const CreateCompetitionCreated(this.competition);

  final Competition competition;

  @override
  List<Object?> get props => [competition];
}
