import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/error/failure.dart';
import 'package:keepscore2/features/competition/domain/competition.model.dart';
import 'package:keepscore2/features/competition/domain/competition_repository.dart';
import 'package:keepscore2/features/competition/presentation/cubit/competition_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockCompetitionRepository extends Mock implements CompetitionRepository {}

CompetitionOverview _overview() => CompetitionOverview(
  competition: Competition(
    id: 'c1',
    joinCode: 'HDHS39',
    name: 'Office Table Tennis',
    ownerId: 'user-1',
    seasonLength: SeasonLength.monthly,
    timezone: 'Europe/Amsterdam',
    startingRating: 1000,
    kFactor: 32,
    movEnabled: true,
    movCap: 2.5,
    allowDraws: true,
    createdAt: DateTime.utc(2026, 8, 9),
  ),
  playerCount: 5,
  matchCount: 11,
  myPlayerId: 'p1',
);

void main() {
  late MockCompetitionRepository repository;

  setUp(() => repository = MockCompetitionRepository());

  blocTest<CompetitionCubit, CompetitionState>(
    'loads the competition',
    setUp: () => when(
      () => repository.overview('c1'),
    ).thenAnswer((_) async => _overview()),
    build: () => CompetitionCubit(repository, 'c1'),
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.competition?.name, 'Office Table Tennis');
      expect(cubit.state.myPlayerId, 'p1');
    },
  );

  blocTest<CompetitionCubit, CompetitionState>(
    'no row is "missing", not a failure — RLS hides a competition the same '
    'way as one that never existed',
    setUp: () =>
        when(() => repository.overview('c1')).thenAnswer((_) async => null),
    build: () => CompetitionCubit(repository, 'c1'),
    act: (cubit) => cubit.load(),
    verify: (cubit) => expect(cubit.state, isA<CompetitionMissing>()),
  );

  blocTest<CompetitionCubit, CompetitionState>(
    'a silent refresh keeps the loaded competition on screen',
    setUp: () => when(
      () => repository.overview('c1'),
    ).thenAnswer((_) async => _overview()),
    build: () => CompetitionCubit(repository, 'c1'),
    act: (cubit) async {
      await cubit.load();
      when(() => repository.overview('c1')).thenThrow(const NetworkFailure());
      await cubit.refresh();
    },
    verify: (cubit) {
      expect(cubit.state, isA<CompetitionReady>());
      expect(cubit.state.competition, isNotNull);
    },
  );
}
