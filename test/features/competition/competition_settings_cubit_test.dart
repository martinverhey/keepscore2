import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/error/failure.dart';
import 'package:keepscore2/features/competition/domain/competition.model.dart';
import 'package:keepscore2/features/competition/domain/competition_repository.dart';
import 'package:keepscore2/features/competition/presentation/cubit/competition_settings_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockCompetitionRepository extends Mock implements CompetitionRepository {}

Competition _competition({
  String name = 'Office Table Tennis',
  SeasonLength seasonLength = SeasonLength.monthly,
  int kFactor = 32,
  bool movEnabled = true,
  double movCap = 2.5,
  bool allowDraws = true,
}) => Competition(
  id: 'c1',
  joinCode: 'HDHS39',
  name: name,
  ownerId: 'user-1',
  seasonLength: seasonLength,
  timezone: 'Europe/Amsterdam',
  startingRating: 1000,
  kFactor: kFactor,
  movEnabled: movEnabled,
  movCap: movCap,
  allowDraws: allowDraws,
  createdAt: DateTime.utc(2026, 8, 9),
);

CompetitionOverview _overview(Competition competition) => CompetitionOverview(
  competition: competition,
  playerCount: 5,
  matchCount: 11,
);

CompetitionSettingsReady _ready(CompetitionSettingsCubit cubit) =>
    cubit.state as CompetitionSettingsReady;

void main() {
  late MockCompetitionRepository repository;

  setUpAll(() => registerFallbackValue(SeasonLength.monthly));

  setUp(() => repository = MockCompetitionRepository());

  void stubLoad([Competition? competition]) {
    when(
      () => repository.overview('c1'),
    ).thenAnswer((_) async => _overview(competition ?? _competition()));
  }

  blocTest<CompetitionSettingsCubit, CompetitionSettingsState>(
    'seeds the form from the stored competition',
    setUp: () => stubLoad(),
    build: () => CompetitionSettingsCubit(repository, 'c1'),
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(_ready(cubit).name, 'Office Table Tennis');
      expect(_ready(cubit).kFactor, '32');
      expect(_ready(cubit).movCap, '2.5');
      expect(_ready(cubit).canSubmit, isTrue);
    },
  );

  blocTest<CompetitionSettingsCubit, CompetitionSettingsState>(
    'a competition the user cannot see reads as missing, not as an error',
    setUp: () =>
        when(() => repository.overview('c1')).thenAnswer((_) async => null),
    build: () => CompetitionSettingsCubit(repository, 'c1'),
    act: (cubit) => cubit.load(),
    verify: (cubit) => expect(cubit.state, isA<CompetitionSettingsMissing>()),
  );

  blocTest<CompetitionSettingsCubit, CompetitionSettingsState>(
    'holds back values Postgres would reject',
    setUp: () => stubLoad(),
    build: () => CompetitionSettingsCubit(repository, 'c1'),
    act: (cubit) async {
      await cubit.load();
      cubit.kFactorChanged('500');
      expect(_ready(cubit).canSubmit, isFalse);
      cubit.kFactorChanged('40');
      expect(_ready(cubit).canSubmit, isTrue);
      cubit.movCapChanged('9');
      expect(_ready(cubit).canSubmit, isFalse);
      cubit.movCapChanged('');
      expect(_ready(cubit).canSubmit, isFalse);
      cubit.nameChanged('X');
      expect(_ready(cubit).canSubmit, isFalse);
    },
  );

  blocTest<CompetitionSettingsCubit, CompetitionSettingsState>(
    'a comma decimal is accepted — a Dutch keyboard produces one',
    setUp: () => stubLoad(),
    build: () => CompetitionSettingsCubit(repository, 'c1'),
    act: (cubit) async {
      await cubit.load();
      cubit.movCapChanged('1,8');
    },
    verify: (cubit) {
      expect(_ready(cubit).movCapIsValid, isTrue);
      expect(_ready(cubit).movCapValue, 1.8);
    },
  );

  blocTest<CompetitionSettingsCubit, CompetitionSettingsState>(
    'saving sends the parsed values and re-seeds from the saved row',
    setUp: () {
      stubLoad();
      when(
        () => repository.updateSettings(
          competitionId: any(named: 'competitionId'),
          name: any(named: 'name'),
          seasonLength: any(named: 'seasonLength'),
          kFactor: any(named: 'kFactor'),
          movEnabled: any(named: 'movEnabled'),
          movCap: any(named: 'movCap'),
          allowDraws: any(named: 'allowDraws'),
        ),
      ).thenAnswer(
        (_) async => _competition(
          name: 'Table Tennis',
          seasonLength: SeasonLength.quarterly,
          kFactor: 24,
          movEnabled: false,
          movCap: 2,
          allowDraws: false,
        ),
      );
    },
    build: () => CompetitionSettingsCubit(repository, 'c1'),
    act: (cubit) async {
      await cubit.load();
      cubit.nameChanged('  Table Tennis  ');
      cubit.seasonLengthChanged(SeasonLength.quarterly);
      cubit.kFactorChanged('24');
      cubit.movEnabledChanged(false);
      cubit.movCapChanged('2,0');
      cubit.allowDrawsChanged(false);
      await cubit.submit();
    },
    verify: (cubit) {
      verify(
        () => repository.updateSettings(
          competitionId: 'c1',
          name: '  Table Tennis  ',
          seasonLength: SeasonLength.quarterly,
          kFactor: 24,
          movEnabled: false,
          movCap: 2.0,
          allowDraws: false,
        ),
      ).called(1);

      expect(_ready(cubit).saved, isTrue);
      expect(_ready(cubit).busy, isFalse);
      expect(_ready(cubit).name, 'Table Tennis');
      expect(_ready(cubit).movCap, '2.0');
    },
  );

  blocTest<CompetitionSettingsCubit, CompetitionSettingsState>(
    'editing after a save retracts the confirmation',
    setUp: () {
      stubLoad();
      when(
        () => repository.updateSettings(
          competitionId: any(named: 'competitionId'),
          name: any(named: 'name'),
          seasonLength: any(named: 'seasonLength'),
          kFactor: any(named: 'kFactor'),
          movEnabled: any(named: 'movEnabled'),
          movCap: any(named: 'movCap'),
          allowDraws: any(named: 'allowDraws'),
        ),
      ).thenAnswer((_) async => _competition());
    },
    build: () => CompetitionSettingsCubit(repository, 'c1'),
    act: (cubit) async {
      await cubit.load();
      await cubit.submit();
      expect(_ready(cubit).saved, isTrue);
      cubit.kFactorChanged('40');
    },
    verify: (cubit) => expect(_ready(cubit).saved, isFalse),
  );

  blocTest<CompetitionSettingsCubit, CompetitionSettingsState>(
    'a rejected save keeps the form and shows why',
    setUp: () {
      stubLoad();
      when(
        () => repository.updateSettings(
          competitionId: any(named: 'competitionId'),
          name: any(named: 'name'),
          seasonLength: any(named: 'seasonLength'),
          kFactor: any(named: 'kFactor'),
          movEnabled: any(named: 'movEnabled'),
          movCap: any(named: 'movCap'),
          allowDraws: any(named: 'allowDraws'),
        ),
      ).thenThrow(const PermissionFailure());
    },
    build: () => CompetitionSettingsCubit(repository, 'c1'),
    act: (cubit) async {
      await cubit.load();
      cubit.kFactorChanged('40');
      await cubit.submit();
    },
    verify: (cubit) {
      expect(_ready(cubit).failure, isA<PermissionFailure>());
      expect(_ready(cubit).saved, isFalse);
      expect(_ready(cubit).busy, isFalse);
      expect(_ready(cubit).kFactor, '40');
    },
  );
}
