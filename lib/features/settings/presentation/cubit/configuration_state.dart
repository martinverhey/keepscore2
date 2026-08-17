import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../competition/domain/competition.model.dart';

sealed class ConfigurationState extends Equatable {
  const ConfigurationState();
}

class ConfigurationLoading extends ConfigurationState {
  const ConfigurationLoading();

  @override
  List<Object?> get props => [];
}

class ConfigurationMissing extends ConfigurationState {
  const ConfigurationMissing();

  @override
  List<Object?> get props => [];
}

class ConfigurationFailed extends ConfigurationState {
  const ConfigurationFailed(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

class ConfigurationReady extends ConfigurationState {
  const ConfigurationReady({
    required this.competition,
    required this.name,
    required this.seasonLength,
    required this.kFactor,
    required this.movEnabled,
    required this.movCap,
    required this.allowDraws,
    this.busy = false,
    this.saved = false,
    this.failure,
  });

  factory ConfigurationReady.of(Competition competition) => ConfigurationReady(
    competition: competition,
    name: competition.name,
    seasonLength: competition.seasonLength,
    kFactor: '${competition.kFactor}',
    movEnabled: competition.movEnabled,
    movCap: _formatCap(competition.movCap),
    allowDraws: competition.allowDraws,
  );

  final Competition competition;
  final String name;
  final SeasonLength seasonLength;
  final String kFactor;
  final bool movEnabled;
  final String movCap;
  final bool allowDraws;
  final bool busy;
  final bool saved;
  final Failure? failure;

  bool get nameIsValid => name.trim().length >= 2;

  int? get kFactorValue => int.tryParse(kFactor.trim());

  bool get kFactorIsValid =>
      kFactorValue != null && kFactorValue! >= 1 && kFactorValue! <= 200;

  double? get movCapValue =>
      double.tryParse(movCap.trim().replaceAll(',', '.'));

  bool get movCapIsValid =>
      movCapValue != null && movCapValue! >= 1 && movCapValue! <= 5;

  bool get canSubmit => nameIsValid && kFactorIsValid && movCapIsValid && !busy;

  ConfigurationReady copyWith({
    Competition? competition,
    String? name,
    SeasonLength? seasonLength,
    String? kFactor,
    bool? movEnabled,
    String? movCap,
    bool? allowDraws,
    bool? busy,
    bool? saved,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return ConfigurationReady(
      competition: competition ?? this.competition,
      name: name ?? this.name,
      seasonLength: seasonLength ?? this.seasonLength,
      kFactor: kFactor ?? this.kFactor,
      movEnabled: movEnabled ?? this.movEnabled,
      movCap: movCap ?? this.movCap,
      allowDraws: allowDraws ?? this.allowDraws,
      busy: busy ?? this.busy,
      saved: saved ?? this.saved,
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
    allowDraws,
    busy,
    saved,
    failure,
  ];
}

String _formatCap(double value) =>
    value == value.roundToDouble() ? value.toStringAsFixed(1) : '$value';
