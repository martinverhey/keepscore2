import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/competition.dart';

enum CompetitionSettingsStatus { loading, ready, missing, failed }

class CompetitionSettingsState extends Equatable {
  const CompetitionSettingsState({
    this.status = CompetitionSettingsStatus.loading,
    this.competition,
    this.name = '',
    this.seasonLength = SeasonLength.monthly,
    this.kFactor = '',
    this.movEnabled = true,
    this.movCap = '',
    this.allowDraws = true,
    this.busy = false,
    this.saved = false,
    this.failure,
  });

  factory CompetitionSettingsState.of(Competition competition) =>
      CompetitionSettingsState(
        status: CompetitionSettingsStatus.ready,
        competition: competition,
        name: competition.name,
        seasonLength: competition.seasonLength,
        kFactor: '${competition.kFactor}',
        movEnabled: competition.movEnabled,
        movCap: _formatCap(competition.movCap),
        allowDraws: competition.allowDraws,
      );

  final CompetitionSettingsStatus status;
  final Competition? competition;
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

  bool get canSubmit =>
      status == CompetitionSettingsStatus.ready &&
      nameIsValid &&
      kFactorIsValid &&
      movCapIsValid &&
      !busy;

  CompetitionSettingsState copyWith({
    CompetitionSettingsStatus? status,
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
    return CompetitionSettingsState(
      status: status ?? this.status,
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
    status,
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
