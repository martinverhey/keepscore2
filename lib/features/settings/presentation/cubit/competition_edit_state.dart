import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/extensions/double.extension.dart';
import '../../../../core/extensions/string.extension.dart';
import '../../../competition/domain/competition.model.dart';
import '../../../match/domain/elo_settings.model.dart';

sealed class CompetitionEditState extends Equatable {
  const CompetitionEditState();
}

class CompetitionEditLoading extends CompetitionEditState {
  const CompetitionEditLoading();

  @override
  List<Object?> get props => [];
}

class CompetitionEditMissing extends CompetitionEditState {
  const CompetitionEditMissing();

  @override
  List<Object?> get props => [];
}

class CompetitionEditFailed extends CompetitionEditState {
  const CompetitionEditFailed(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

class CompetitionEditSaved extends CompetitionEditState {
  const CompetitionEditSaved(this.competition);

  final Competition competition;

  @override
  List<Object?> get props => [competition];
}

class CompetitionEditReady extends CompetitionEditState {
  const CompetitionEditReady({
    required this.competition,
    required this.name,
    required this.seasonLength,
    required this.kFactor,
    required this.movEnabled,
    required this.movCap,
    required this.shutoutBonus,
    required this.shutoutMultiplier,
    this.busy = false,
    this.failure,
  });

  factory CompetitionEditReady.of(Competition competition) =>
      CompetitionEditReady(
        competition: competition,
        name: competition.name,
        seasonLength: competition.seasonLength,
        kFactor: '${competition.kFactor}',
        movEnabled: competition.movEnabled,
        movCap: competition.movCap.inputLabel,
        shutoutBonus: competition.shutoutBonus,
        shutoutMultiplier: competition.shutoutMultiplier.inputLabel,
      );

  final Competition competition;
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

  CompetitionEditReady copyWith({
    Competition? competition,
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
    return CompetitionEditReady(
      competition: competition ?? this.competition,
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
    competition,
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
