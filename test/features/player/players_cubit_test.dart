import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/error/failure.dart';
import 'package:keepscore2/features/player/domain/player.dart';
import 'package:keepscore2/features/player/domain/player_repository.dart';
import 'package:keepscore2/features/player/presentation/cubit/players_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockPlayerRepository extends Mock implements PlayerRepository {}

Player _player(
  String id,
  String name, {
  String? userId,
  bool isActive = true,
}) =>
    Player(
      id: id,
      competitionId: 'c1',
      displayName: name,
      isActive: isActive,
      userId: userId,
    );

void main() {
  late MockPlayerRepository repository;

  setUp(() => repository = MockPlayerRepository());

  void stubRoster(List<Player> players) {
    when(() => repository.roster('c1')).thenAnswer((_) async => players);
  }

  blocTest<PlayersCubit, PlayersState>(
    'loads the roster',
    setUp: () => stubRoster([_player('p1', 'Ada'), _player('p2', 'Grace')]),
    build: () => PlayersCubit(repository, 'c1'),
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.status, PlayersStatus.ready);
      expect(cubit.state.active, hasLength(2));
      expect(cubit.state.inactive, isEmpty);
    },
  );

  blocTest<PlayersCubit, PlayersState>(
    'a failed load surfaces the error',
    setUp: () => when(() => repository.roster('c1'))
        .thenThrow(const NetworkFailure()),
    build: () => PlayersCubit(repository, 'c1'),
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.status, PlayersStatus.failed);
      expect(cubit.state.failure, isA<NetworkFailure>());
    },
  );

  blocTest<PlayersCubit, PlayersState>(
    'a silent refresh keeps the current roster when the refetch fails',
    setUp: () {
      stubRoster([_player('p1', 'Ada')]);
    },
    build: () => PlayersCubit(repository, 'c1'),
    act: (cubit) async {
      await cubit.load();
      when(() => repository.roster('c1')).thenThrow(const NetworkFailure());
      await cubit.refresh();
    },
    verify: (cubit) {
      expect(cubit.state.status, PlayersStatus.failed);
      expect(cubit.state.players, hasLength(1));
    },
  );

  blocTest<PlayersCubit, PlayersState>(
    'an added placeholder lands in name order without a refetch',
    setUp: () {
      stubRoster([_player('p1', 'Ada'), _player('p3', 'Zoe')]);
      when(() => repository.addPlaceholder(
            competitionId: any(named: 'competitionId'),
            displayName: any(named: 'displayName'),
          )).thenAnswer((_) async => _player('p2', 'Grace'));
    },
    build: () => PlayersCubit(repository, 'c1'),
    act: (cubit) async {
      await cubit.load();
      await cubit.addPlaceholder('Grace');
    },
    verify: (cubit) {
      expect(
        cubit.state.players.map((player) => player.displayName),
        ['Ada', 'Grace', 'Zoe'],
      );
      verify(() => repository.roster('c1')).called(1);
    },
  );

  blocTest<PlayersCubit, PlayersState>(
    'a rename replaces the row and re-sorts it',
    setUp: () {
      stubRoster([_player('p1', 'Ada'), _player('p2', 'Grace')]);
      when(() => repository.rename(
            playerId: 'p1',
            displayName: 'Zoe',
          )).thenAnswer((_) async => _player('p1', 'Zoe'));
    },
    build: () => PlayersCubit(repository, 'c1'),
    act: (cubit) async {
      await cubit.load();
      await cubit.rename('p1', 'Zoe');
    },
    verify: (cubit) => expect(
      cubit.state.players.map((player) => player.displayName),
      ['Grace', 'Zoe'],
    ),
  );

  blocTest<PlayersCubit, PlayersState>(
    'removing a player moves them out of the active roster',
    setUp: () {
      stubRoster([_player('p1', 'Ada'), _player('p2', 'Grace')]);
      when(() => repository.setActive(playerId: 'p2', isActive: false))
          .thenAnswer((_) async => _player('p2', 'Grace', isActive: false));
    },
    build: () => PlayersCubit(repository, 'c1'),
    act: (cubit) async {
      await cubit.load();
      await cubit.setActive('p2', isActive: false);
    },
    verify: (cubit) {
      expect(cubit.state.active.map((player) => player.id), ['p1']);
      expect(cubit.state.inactive.map((player) => player.id), ['p2']);
    },
  );

  blocTest<PlayersCubit, PlayersState>(
    'a refused edit is reported without disturbing the roster',
    setUp: () {
      stubRoster([_player('p1', 'Ada')]);
      when(() => repository.rename(
            playerId: any(named: 'playerId'),
            displayName: any(named: 'displayName'),
          )).thenThrow(const PermissionFailure());
    },
    build: () => PlayersCubit(repository, 'c1'),
    act: (cubit) async {
      await cubit.load();
      final ok = await cubit.rename('p1', 'Grace');
      expect(ok, isFalse);
    },
    verify: (cubit) {
      expect(cubit.state.actionFailure, isA<PermissionFailure>());
      expect(cubit.state.failure, isNull);
      expect(cubit.state.players.single.displayName, 'Ada');
      expect(cubit.state.busy, isFalse);
    },
  );
}
