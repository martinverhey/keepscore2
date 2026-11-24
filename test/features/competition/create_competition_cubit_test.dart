import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/error/failure.dart';
import 'package:keepscore2/features/competition/domain/competition.model.dart';
import 'package:keepscore2/features/competition/domain/competition_repository.dart';
import 'package:keepscore2/features/competition/presentation/cubit/create_competition_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockCompetitionRepository extends Mock implements CompetitionRepository {}

final _created = Competition(
  id: 'comp-1',
  joinCode: 'HDHS39',
  name: 'Office Table Tennis',
  ownerId: 'user-1',
  seasonLength: SeasonLength.quarterly,
  timezone: 'Europe/Amsterdam',
  startingRating: 1000,
  kFactor: 32,
  movEnabled: true,
  movCap: 2.5,
  shutoutBonus: true,
  createdAt: DateTime.utc(2026, 8, 9),
);

CreateCompetitionEditing _editing(String name) => CreateCompetitionEditing(
  name: name,
  kFactor: '60',
  movCap: '10',
  shutoutMultiplier: '2',
);

void main() {
  late MockCompetitionRepository repository;

  setUp(() {
    repository = MockCompetitionRepository();
    registerFallbackValue(SeasonLength.monthly);
    when(
      () => repository.create(
        name: any(named: 'name'),
        seasonLength: any(named: 'seasonLength'),
        kFactor: any(named: 'kFactor'),
        movEnabled: any(named: 'movEnabled'),
        movCap: any(named: 'movCap'),
        shutoutBonus: any(named: 'shutoutBonus'),
        shutoutMultiplier: any(named: 'shutoutMultiplier'),
        displayName: any(named: 'displayName'),
      ),
    ).thenAnswer((_) async => _created);
  });

  test('a name needs at least two characters', () {
    expect(_editing('').nameIsValid, isFalse);
    expect(_editing('A').nameIsValid, isFalse);
    expect(_editing('  A  ').nameIsValid, isFalse);
    expect(_editing('Pool').nameIsValid, isTrue);
  });

  test('defaults to quarterly seasons', () {
    expect(_editing('').seasonLength, SeasonLength.quarterly);
  });

  blocTest<CreateCompetitionCubit, CreateCompetitionState>(
    'submits the chosen name and season length',
    build: () => CreateCompetitionCubit(repository),
    act: (cubit) async {
      cubit.nameChanged('Office Table Tennis');
      cubit.seasonLengthChanged(SeasonLength.quarterly);
      await cubit.submit();
    },
    verify: (cubit) {
      verify(
        () => repository.create(
          name: 'Office Table Tennis',
          seasonLength: SeasonLength.quarterly,
          kFactor: 60,
          movEnabled: true,
          movCap: 10,
          shutoutBonus: true,
          shutoutMultiplier: 2,
        ),
      ).called(1);
      expect(cubit.state, CreateCompetitionCreated(_created));
    },
  );

  test('starts on the default rating settings', () {
    final state = CreateCompetitionCubit(repository).state;
    expect(state, isA<CreateCompetitionEditing>());
    state as CreateCompetitionEditing;
    expect(state.kFactor, '60');
    expect(state.movEnabled, isTrue);
    expect(state.movCap, '10');
    expect(state.shutoutBonus, isTrue);
    expect(state.shutoutMultiplier, '2');
    expect(state.seasonLength, SeasonLength.quarterly);
  });

  blocTest<CreateCompetitionCubit, CreateCompetitionState>(
    'submits the advanced rating settings',
    build: () => CreateCompetitionCubit(repository),
    act: (cubit) async {
      cubit.nameChanged('Office Table Tennis');
      cubit.kFactorChanged('40');
      cubit.movEnabledChanged(false);
      cubit.movCapChanged('5,5');
      cubit.shutoutBonusChanged(false);
      cubit.shutoutMultiplierChanged('1,5');
      await cubit.submit();
    },
    verify: (_) => verify(
      () => repository.create(
        name: 'Office Table Tennis',
        seasonLength: SeasonLength.quarterly,
        kFactor: 40,
        movEnabled: false,
        movCap: 5.5,
        shutoutBonus: false,
        shutoutMultiplier: 1.5,
      ),
    ).called(1),
  );

  test('holds back rating settings Postgres would reject', () {
    final valid = _editing('Pool');
    expect(valid.canSubmit, isTrue);
    expect(valid.copyWith(kFactor: '0').canSubmit, isFalse);
    expect(valid.copyWith(kFactor: '201').canSubmit, isFalse);
    expect(valid.copyWith(kFactor: '').canSubmit, isFalse);
    expect(valid.copyWith(movCap: '0,5').canSubmit, isFalse);
    expect(valid.copyWith(movCap: '51').canSubmit, isFalse);
    expect(valid.copyWith(movCap: '').canSubmit, isFalse);
    expect(valid.copyWith(shutoutMultiplier: '0,5').canSubmit, isFalse);
    expect(valid.copyWith(shutoutMultiplier: '11').canSubmit, isFalse);
  });

  blocTest<CreateCompetitionCubit, CreateCompetitionState>(
    'will not submit an invalid name',
    build: () => CreateCompetitionCubit(repository),
    act: (cubit) async {
      cubit.nameChanged('X');
      await cubit.submit();
    },
    verify: (_) => verifyNever(
      () => repository.create(
        name: any(named: 'name'),
        seasonLength: any(named: 'seasonLength'),
        kFactor: any(named: 'kFactor'),
        movEnabled: any(named: 'movEnabled'),
        movCap: any(named: 'movCap'),
        shutoutBonus: any(named: 'shutoutBonus'),
        shutoutMultiplier: any(named: 'shutoutMultiplier'),
      ),
    ),
  );

  blocTest<CreateCompetitionCubit, CreateCompetitionState>(
    'surfaces the server refusal when a guest gets this far',
    setUp: () =>
        when(
          () => repository.create(
            name: any(named: 'name'),
            seasonLength: any(named: 'seasonLength'),
            kFactor: any(named: 'kFactor'),
            movEnabled: any(named: 'movEnabled'),
            movCap: any(named: 'movCap'),
            shutoutBonus: any(named: 'shutoutBonus'),
            shutoutMultiplier: any(named: 'shutoutMultiplier'),
            displayName: any(named: 'displayName'),
          ),
        ).thenThrow(
          const ValidationFailure('Create an account to start a competition'),
        ),
    build: () => CreateCompetitionCubit(repository),
    act: (cubit) async {
      cubit.nameChanged('Office Table Tennis');
      await cubit.submit();
    },
    verify: (cubit) {
      final state = cubit.state as CreateCompetitionEditing;
      expect(state.busy, isFalse);
      expect(
        (state.failure! as ValidationFailure).message,
        'Create an account to start a competition',
      );
    },
  );
}
