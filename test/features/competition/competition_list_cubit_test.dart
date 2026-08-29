import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/error/failure.dart';
import 'package:keepscore2/features/auth/domain/auth_repository.dart';
import 'package:keepscore2/features/auth/domain/auth_user.model.dart';
import 'package:keepscore2/features/auth/presentation/cubit/auth_bloc.dart';
import 'package:keepscore2/features/competition/domain/competition.model.dart';
import 'package:keepscore2/features/competition/domain/competition_repository.dart';
import 'package:keepscore2/features/competition/presentation/cubit/competition_list_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockCompetitionRepository extends Mock implements CompetitionRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

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
  late MockAuthRepository auth;
  late AuthBloc authBloc;
  late StreamController<AuthUser?> authEvents;

  setUp(() {
    repository = MockCompetitionRepository();
    auth = MockAuthRepository();
    authEvents = StreamController<AuthUser?>.broadcast();
    when(() => auth.currentUser).thenReturn(
      const AuthUser(id: 'user-1', displayName: 'Ada', isGuest: false),
    );
    when(() => auth.watchUser()).thenAnswer((_) => authEvents.stream);
    authBloc = AuthBloc(auth);
  });

  tearDown(() async {
    await authEvents.close();
    await authBloc.close();
  });

  blocTest<CompetitionListCubit, CompetitionListState>(
    'loads the list',
    setUp: () => when(
      () => repository.myCompetitions(),
    ).thenAnswer((_) async => [_overview('c1', 'Office Table Tennis')]),
    build: () => CompetitionListCubit(repository, authBloc),
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
    build: () => CompetitionListCubit(repository, authBloc),
    act: (cubit) => cubit.load(),
    verify: (cubit) => expect(_ready(cubit).isEmpty, isTrue),
  );

  blocTest<CompetitionListCubit, CompetitionListState>(
    'a failed first load surfaces the error',
    setUp: () => when(
      () => repository.myCompetitions(),
    ).thenThrow(const NetworkFailure()),
    build: () => CompetitionListCubit(repository, authBloc),
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
    build: () => CompetitionListCubit(repository, authBloc),
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
    build: () => CompetitionListCubit(repository, authBloc),
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
    build: () => CompetitionListCubit(repository, authBloc),
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
    build: () => CompetitionListCubit(repository, authBloc),
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
    build: () => CompetitionListCubit(repository, authBloc),
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
    build: () => CompetitionListCubit(repository, authBloc),
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

  blocTest<CompetitionListCubit, CompetitionListState>(
    'ensureLoaded fetches once and then serves the cached list',
    setUp: () => when(
      () => repository.myCompetitions(),
    ).thenAnswer((_) async => [_overview('c1', 'Office Table Tennis')]),
    build: () => CompetitionListCubit(repository, authBloc),
    act: (cubit) async {
      await cubit.ensureLoaded();
      await cubit.ensureLoaded();
    },
    verify: (cubit) {
      expect(_ready(cubit).competitions, hasLength(1));
      verify(() => repository.myCompetitions()).called(1);
    },
  );

  blocTest<CompetitionListCubit, CompetitionListState>(
    'concurrent ensureLoaded callers share a single request',
    setUp: () {
      final pending = Completer<List<CompetitionOverview>>();
      when(() => repository.myCompetitions()).thenAnswer((_) {
        if (!pending.isCompleted) {
          pending.complete([_overview('c1', 'Office Table Tennis')]);
        }
        return pending.future;
      });
    },
    build: () => CompetitionListCubit(repository, authBloc),
    act: (cubit) => Future.wait([cubit.ensureLoaded(), cubit.ensureLoaded()]),
    verify: (cubit) {
      expect(_ready(cubit).competitions, hasLength(1));
      verify(() => repository.myCompetitions()).called(1);
    },
  );

  blocTest<CompetitionListCubit, CompetitionListState>(
    'a failed ensureLoaded is retried rather than cached as empty',
    setUp: () {
      var call = 0;
      when(() => repository.myCompetitions()).thenAnswer((_) async {
        if (call++ == 0) throw const NetworkFailure();
        return [_overview('c1', 'Office Table Tennis')];
      });
    },
    build: () => CompetitionListCubit(repository, authBloc),
    act: (cubit) async {
      await cubit.ensureLoaded();
      expect(cubit.state, isA<CompetitionListFailed>());
      await cubit.ensureLoaded();
    },
    verify: (cubit) {
      expect(_ready(cubit).competitions, hasLength(1));
      verify(() => repository.myCompetitions()).called(2);
    },
  );

  blocTest<CompetitionListCubit, CompetitionListState>(
    'isMember answers from the loaded list',
    setUp: () => when(
      () => repository.myCompetitions(),
    ).thenAnswer((_) async => [_overview('c1', 'Office Table Tennis')]),
    build: () => CompetitionListCubit(repository, authBloc),
    act: (cubit) => cubit.ensureLoaded(),
    verify: (cubit) {
      expect(cubit.isMember('c1'), isTrue);
      expect(cubit.isMember('c2'), isFalse);
    },
  );

  blocTest<CompetitionListCubit, CompetitionListState>(
    'signing out drops the cache so the next account refetches',
    setUp: () => when(
      () => repository.myCompetitions(),
    ).thenAnswer((_) async => [_overview('c1', 'Office Table Tennis')]),
    build: () => CompetitionListCubit(repository, authBloc),
    act: (cubit) async {
      await cubit.ensureLoaded();
      authEvents.add(null);
      await authBloc.stream.firstWhere((session) => !session.isAuthenticated);
      expect(cubit.state, isA<CompetitionListLoading>());
      await cubit.ensureLoaded();
    },
    verify: (cubit) => verify(() => repository.myCompetitions()).called(2),
  );
}
