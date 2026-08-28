import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/error/failure.dart';
import 'package:keepscore2/features/auth/domain/auth_repository.dart';
import 'package:keepscore2/features/auth/domain/auth_user.model.dart';
import 'package:keepscore2/features/auth/presentation/cubit/auth_bloc.dart';
import 'package:keepscore2/features/competition/domain/competition.model.dart';
import 'package:keepscore2/features/competition/domain/competition_repository.dart';
import 'package:keepscore2/features/competition/presentation/cubit/competition_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockCompetitionRepository extends Mock implements CompetitionRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

CompetitionOverview _overview({
  String id = 'c1',
  String name = 'Office Table Tennis',
}) => CompetitionOverview(
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
  myPlayerId: 'p1',
);

void main() {
  late MockCompetitionRepository repository;
  late AuthBloc authBloc;
  late StreamController<AuthUser?> users;

  setUp(() {
    repository = MockCompetitionRepository();

    final auth = MockAuthRepository();
    users = StreamController<AuthUser?>.broadcast();
    when(() => auth.currentUser).thenReturn(
      const AuthUser(id: 'user-1', displayName: 'Ada', isGuest: false),
    );
    when(() => auth.watchUser()).thenAnswer((_) => users.stream);
    authBloc = AuthBloc(auth);
    addTearDown(users.close);
    addTearDown(authBloc.close);
  });

  CompetitionCubit build() {
    final cubit = CompetitionCubit(repository, authBloc);
    addTearDown(cubit.close);
    return cubit;
  }

  blocTest<CompetitionCubit, CompetitionState>(
    'loads the competition',
    setUp: () => when(
      () => repository.overview('c1'),
    ).thenAnswer((_) async => _overview()),
    build: () => CompetitionCubit(repository, authBloc),
    act: (cubit) => cubit.select('c1'),
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
    build: () => CompetitionCubit(repository, authBloc),
    act: (cubit) => cubit.select('c1'),
    verify: (cubit) => expect(cubit.state, isA<CompetitionMissing>()),
  );

  blocTest<CompetitionCubit, CompetitionState>(
    'a silent refresh keeps the loaded competition on screen',
    setUp: () => when(
      () => repository.overview('c1'),
    ).thenAnswer((_) async => _overview()),
    build: () => CompetitionCubit(repository, authBloc),
    act: (cubit) async {
      await cubit.select('c1');
      when(() => repository.overview('c1')).thenThrow(const NetworkFailure());
      await cubit.refresh();
    },
    verify: (cubit) {
      expect(cubit.state, isA<CompetitionReady>());
      expect(cubit.state.competition, isNotNull);
    },
  );

  test(
    'selecting another competition clears the previous one while it loads',
    () async {
      final pendingSecond = Completer<CompetitionOverview?>();
      when(
        () => repository.overview('c1'),
      ).thenAnswer((_) async => _overview());
      when(
        () => repository.overview('c2'),
      ).thenAnswer((_) => pendingSecond.future);

      final cubit = build();
      await cubit.select('c1');
      expect(cubit.state, isA<CompetitionReady>());

      final second = cubit.select('c2');
      expect(cubit.state, isA<CompetitionLoading>());

      pendingSecond.complete(_overview(id: 'c2', name: 'Darts'));
      await second;
      expect(cubit.competitionId, 'c2');
      expect(cubit.state.competition?.name, 'Darts');
    },
  );

  test(
    'a response for a competition that is no longer selected is dropped',
    () async {
      final pendingFirst = Completer<CompetitionOverview?>();
      when(
        () => repository.overview('c1'),
      ).thenAnswer((_) => pendingFirst.future);
      when(
        () => repository.overview('c2'),
      ).thenAnswer((_) async => _overview(id: 'c2', name: 'Darts'));

      final cubit = build();
      final first = cubit.select('c1');
      await cubit.select('c2');
      expect(cubit.state.competition?.name, 'Darts');

      pendingFirst.complete(_overview());
      await first;
      expect(cubit.state.competition?.name, 'Darts');
    },
  );

  test('re-selecting the same competition refreshes it in place', () async {
    when(() => repository.overview('c1')).thenAnswer((_) async => _overview());

    final cubit = build();
    await cubit.select('c1');

    final states = <CompetitionState>[];
    final subscription = cubit.stream.listen(states.add);
    addTearDown(subscription.cancel);

    await cubit.select('c1');

    expect(states.whereType<CompetitionLoading>(), isEmpty);
    verify(() => repository.overview('c1')).called(2);
  });

  test('signing out drops the selected competition', () async {
    when(() => repository.overview('c1')).thenAnswer((_) async => _overview());

    final cubit = build();
    await cubit.select('c1');
    expect(cubit.state, isA<CompetitionReady>());

    users.add(null);
    await authBloc.stream.firstWhere((session) => !session.isAuthenticated);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.competitionId, isNull);
    expect(cubit.state.competition, isNull);
  });

  test(
    'leaving the selected competition drops it, another one does not',
    () async {
      when(
        () => repository.overview('c1'),
      ).thenAnswer((_) async => _overview());

      final cubit = build();
      await cubit.select('c1');

      cubit.clearIfSelected('c2');
      expect(cubit.state, isA<CompetitionReady>());

      cubit.clearIfSelected('c1');
      expect(cubit.competitionId, isNull);
      expect(cubit.state.competition, isNull);
    },
  );
}
