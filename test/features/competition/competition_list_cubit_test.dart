import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/error/failure.dart';
import 'package:keepscore2/features/competition/domain/competition.dart';
import 'package:keepscore2/features/competition/domain/competition_repository.dart';
import 'package:keepscore2/features/competition/presentation/cubit/competition_list_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockCompetitionRepository extends Mock implements CompetitionRepository {}

CompetitionOverview _overview(String id, String name) => CompetitionOverview(
      competition: Competition(
        id: id,
        joinCode: 'HDHS39',
        name: name,
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
    );

void main() {
  late MockCompetitionRepository repository;

  setUp(() => repository = MockCompetitionRepository());

  blocTest<CompetitionListCubit, CompetitionListState>(
    'loads the list',
    setUp: () => when(() => repository.myCompetitions())
        .thenAnswer((_) async => [_overview('c1', 'Office Table Tennis')]),
    build: () => CompetitionListCubit(repository),
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.status, CompetitionListStatus.ready);
      expect(cubit.state.competitions, hasLength(1));
      expect(cubit.state.isEmpty, isFalse);
    },
  );

  blocTest<CompetitionListCubit, CompetitionListState>(
    'an empty result is a ready state, not a failure',
    setUp: () =>
        when(() => repository.myCompetitions()).thenAnswer((_) async => []),
    build: () => CompetitionListCubit(repository),
    act: (cubit) => cubit.load(),
    verify: (cubit) => expect(cubit.state.isEmpty, isTrue),
  );

  blocTest<CompetitionListCubit, CompetitionListState>(
    'a failed first load surfaces the error',
    setUp: () => when(() => repository.myCompetitions())
        .thenThrow(const NetworkFailure()),
    build: () => CompetitionListCubit(repository),
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.status, CompetitionListStatus.failed);
      expect(cubit.state.failure, isA<NetworkFailure>());
    },
  );

  blocTest<CompetitionListCubit, CompetitionListState>(
    'a failed refresh keeps the list on screen',
    setUp: () {
      var call = 0;
      when(() => repository.myCompetitions()).thenAnswer((_) async {
        if (call++ == 0) return [_overview('c1', 'Office Table Tennis')];
        throw const NetworkFailure();
      });
    },
    build: () => CompetitionListCubit(repository),
    act: (cubit) async {
      await cubit.load();
      await cubit.refresh();
    },
    verify: (cubit) {
      expect(cubit.state.status, CompetitionListStatus.failed);
      expect(cubit.state.competitions, hasLength(1));
    },
  );

  blocTest<CompetitionListCubit, CompetitionListState>(
    'a refresh does not flash the loading state',
    setUp: () => when(() => repository.myCompetitions())
        .thenAnswer((_) async => [_overview('c1', 'Office Table Tennis')]),
    build: () => CompetitionListCubit(repository),
    act: (cubit) async {
      await cubit.load();
      await cubit.refresh();
    },
    verify: (cubit) {
      expect(cubit.state.status, CompetitionListStatus.ready);
    },
  );
}
