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
  allowDraws: true,
  createdAt: DateTime.utc(2026, 8, 9),
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
        displayName: any(named: 'displayName'),
      ),
    ).thenAnswer((_) async => _created);
  });

  test('a name needs at least two characters', () {
    expect(const CreateCompetitionEditing(name: '').nameIsValid, isFalse);
    expect(const CreateCompetitionEditing(name: 'A').nameIsValid, isFalse);
    expect(const CreateCompetitionEditing(name: '  A  ').nameIsValid, isFalse);
    expect(const CreateCompetitionEditing(name: 'Pool').nameIsValid, isTrue);
  });

  test('defaults to monthly seasons', () {
    expect(const CreateCompetitionEditing().seasonLength, SeasonLength.monthly);
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
        ),
      ).called(1);
      expect(cubit.state, CreateCompetitionCreated(_created));
    },
  );

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
