import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/error/failure.dart';
import 'package:keepscore2/features/competition/domain/competition.model.dart';
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

CompetitionListReady _ready(CompetitionListCubit cubit) =>
    cubit.state as CompetitionListReady;

void main() {
  late MockCompetitionRepository repository;

  setUp(() => repository = MockCompetitionRepository());

  blocTest<CompetitionListCubit, CompetitionListState>(
    'loads the list',
    setUp: () => when(
      () => repository.myCompetitions(),
    ).thenAnswer((_) async => [_overview('c1', 'Office Table Tennis')]),
    build: () => CompetitionListCubit(repository),
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(_ready(cubit).competitions, hasLength(1));
      expect(_ready(cubit).isEmpty, isFalse);
    },
  );

  blocTest<CompetitionListCubit, CompetitionListState>(
    'an empty result is a ready state, not a failure',
    setUp: () =>
        when(() => repository.myCompetitions()).thenAnswer((_) async => []),
    build: () => CompetitionListCubit(repository),
    act: (cubit) => cubit.load(),
    verify: (cubit) => expect(_ready(cubit).isEmpty, isTrue),
  );

  blocTest<CompetitionListCubit, CompetitionListState>(
    'a failed first load surfaces the error',
    setUp: () => when(
      () => repository.myCompetitions(),
    ).thenThrow(const NetworkFailure()),
    build: () => CompetitionListCubit(repository),
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(
        (cubit.state as CompetitionListFailed).failure,
        isA<NetworkFailure>(),
      );
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
      expect(cubit.state, isA<CompetitionListReady>());
      expect(_ready(cubit).competitions, hasLength(1));
    },
  );

  blocTest<CompetitionListCubit, CompetitionListState>(
    'a refresh does not flash the loading state',
    setUp: () => when(
      () => repository.myCompetitions(),
    ).thenAnswer((_) async => [_overview('c1', 'Office Table Tennis')]),
    build: () => CompetitionListCubit(repository),
    act: (cubit) async {
      await cubit.load();
      await cubit.refresh();
    },
    verify: (cubit) {
      expect(cubit.state, isA<CompetitionListReady>());
    },
  );

  blocTest<CompetitionListCubit, CompetitionListState>(
    'a rename sends the full settings and refreshes the list',
    setUp: () {
      var call = 0;
      when(() => repository.myCompetitions()).thenAnswer((_) async {
        call++;
        return [
          _overview(
            'c1',
            call == 1 ? 'Office Table Tennis' : 'Table Tennis League',
          ),
        ];
      });
      when(
        () => repository.updateSettings(
          competitionId: 'c1',
          name: 'Table Tennis League',
          seasonLength: SeasonLength.monthly,
          kFactor: 32,
          movEnabled: true,
          movCap: 2.5,
          allowDraws: true,
        ),
      ).thenAnswer(
        (_) async => _overview('c1', 'Table Tennis League').competition,
      );
    },
    build: () => CompetitionListCubit(repository),
    act: (cubit) async {
      await cubit.load();
      final ok = await cubit.rename('c1', 'Table Tennis League');
      expect(ok, isTrue);
    },
    verify: (cubit) {
      expect(
        _ready(cubit).competitions.single.competition.name,
        'Table Tennis League',
      );
      expect(_ready(cubit).busy, isFalse);
      verify(() => repository.myCompetitions()).called(2);
    },
  );

  blocTest<CompetitionListCubit, CompetitionListState>(
    'leaving drops the competition off the list',
    setUp: () {
      var call = 0;
      when(() => repository.myCompetitions()).thenAnswer((_) async {
        call++;
        return call == 1 ? [_overview('c1', 'Office Table Tennis')] : [];
      });
      when(() => repository.leave('c1')).thenAnswer((_) async {});
    },
    build: () => CompetitionListCubit(repository),
    act: (cubit) async {
      await cubit.load();
      final ok = await cubit.leave('c1');
      expect(ok, isTrue);
    },
    verify: (cubit) => expect(_ready(cubit).competitions, isEmpty),
  );

  blocTest<CompetitionListCubit, CompetitionListState>(
    'deleting drops the competition off the list',
    setUp: () {
      var call = 0;
      when(() => repository.myCompetitions()).thenAnswer((_) async {
        call++;
        return call == 1 ? [_overview('c1', 'Office Table Tennis')] : [];
      });
      when(() => repository.delete('c1')).thenAnswer((_) async {});
    },
    build: () => CompetitionListCubit(repository),
    act: (cubit) async {
      await cubit.load();
      final ok = await cubit.delete('c1');
      expect(ok, isTrue);
    },
    verify: (cubit) => expect(_ready(cubit).competitions, isEmpty),
  );

  blocTest<CompetitionListCubit, CompetitionListState>(
    'a refused delete is reported without disturbing the list',
    setUp: () {
      when(
        () => repository.myCompetitions(),
      ).thenAnswer((_) async => [_overview('c1', 'Office Table Tennis')]);
      when(() => repository.delete('c1')).thenThrow(const PermissionFailure());
    },
    build: () => CompetitionListCubit(repository),
    act: (cubit) async {
      await cubit.load();
      final ok = await cubit.delete('c1');
      expect(ok, isFalse);
    },
    verify: (cubit) {
      expect(_ready(cubit).actionFailure, isA<PermissionFailure>());
      expect(_ready(cubit).competitions, hasLength(1));
      expect(_ready(cubit).busy, isFalse);
    },
  );
}
