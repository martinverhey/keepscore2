import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/competition.dart';
import '../../domain/competition_repository.dart';

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

  double? get movCapValue => double.tryParse(movCap.trim().replaceAll(',', '.'));

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

class CompetitionSettingsCubit extends Cubit<CompetitionSettingsState> {
  CompetitionSettingsCubit(this._repository, this.competitionId)
      : super(const CompetitionSettingsState());

  final CompetitionRepository _repository;
  final String competitionId;

  Future<void> load() async {
    emit(const CompetitionSettingsState());
    try {
      final overview = await _repository.overview(competitionId);
      if (isClosed) return;
      emit(overview == null
          ? const CompetitionSettingsState(
              status: CompetitionSettingsStatus.missing,
            )
          : CompetitionSettingsState.of(overview.competition));
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(CompetitionSettingsState(
        status: CompetitionSettingsStatus.failed,
        failure: failure,
      ));
    }
  }

  void nameChanged(String value) => _edit(state.copyWith(name: value));

  void seasonLengthChanged(SeasonLength value) =>
      _edit(state.copyWith(seasonLength: value));

  void kFactorChanged(String value) => _edit(state.copyWith(kFactor: value));

  void movEnabledChanged(bool value) =>
      _edit(state.copyWith(movEnabled: value));

  void movCapChanged(String value) => _edit(state.copyWith(movCap: value));

  void allowDrawsChanged(bool value) =>
      _edit(state.copyWith(allowDraws: value));

  void _edit(CompetitionSettingsState next) =>
      emit(next.copyWith(saved: false, clearFailure: true));

  Future<void> submit() async {
    if (!state.canSubmit) return;
    emit(state.copyWith(busy: true, saved: false, clearFailure: true));
    try {
      final competition = await _repository.updateSettings(
        competitionId: competitionId,
        name: state.name,
        seasonLength: state.seasonLength,
        kFactor: state.kFactorValue!,
        movEnabled: state.movEnabled,
        movCap: state.movCapValue!,
        allowDraws: state.allowDraws,
      );
      if (isClosed) return;
      emit(CompetitionSettingsState.of(competition).copyWith(saved: true));
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(state.copyWith(busy: false, failure: failure));
    }
  }
}

String _formatCap(double value) =>
    value == value.roundToDouble() ? value.toStringAsFixed(1) : '$value';
