import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/error/failure.dart';
import 'package:keepscore2/features/player/domain/player.model.dart';
import 'package:keepscore2/features/player/domain/player_repository.dart';
import 'package:keepscore2/features/player/presentation/cubit/players_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockPlayerRepository extends Mock implements PlayerRepository {}

Player _player(
  String id,
  String name, {
  String? userId,
  bool isActive = true,
}) => Player(
  id: id,
  competitionId: 'c1',
  displayName: name,
  isActive: isActive,
  userId: userId,
);

PlayersReady _ready(PlayersCubit cubit) => cubit.state as PlayersReady;

void main() {
  late MockPlayerRepository repository;

  setUp(() => repository = MockPlayerRepository());

  void stubRoster(List<Player> players) {
    when(
      () => repository.currentPlayers('c1'),
    ).thenAnswer((_) async => players);
  }

  blocTest<PlayersCubit, PlayersState>(
    'loads the roster',
    setUp: () => stubRoster([_player('p1', 'Ada'), _player('p2', 'Grace')]),
    build: () => PlayersCubit(repository, 'c1'),
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      final state = cubit.state as PlayersReady;
      expect(state.active, hasLength(2));
      expect(state.inactive, isEmpty);
    },
  );

  blocTest<PlayersCubit, PlayersState>(
    'loads the roster sorted a to z, regardless of server order',
    setUp: () => stubRoster([
      _player('p1', 'Zoe'),
      _player('p2', 'ada'),
      _player('p3', 'Grace'),
    ]),
    build: () => PlayersCubit(repository, 'c1'),
    act: (cubit) => cubit.load(),
    verify: (cubit) => expect(
      (cubit.state as PlayersReady).players.map((player) => player.displayName),
      ['ada', 'Grace', 'Zoe'],
    ),
  );

  blocTest<PlayersCubit, PlayersState>(
    'splits the active roster into claimed and unclaimed players',
    setUp: () => stubRoster([
      _player('p1', 'Ada', userId: 'u1'),
      _player('p2', 'Grace'),
    ]),
    build: () => PlayersCubit(repository, 'c1'),
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      final state = cubit.state as PlayersReady;
      expect(state.claimed.map((player) => player.id), ['p1']);
      expect(state.unclaimed.map((player) => player.id), ['p2']);
    },
  );

  blocTest<PlayersCubit, PlayersState>(
    'a failed load surfaces the error',
    setUp: () => when(
      () => repository.currentPlayers('c1'),
    ).thenThrow(const NetworkFailure()),
    build: () => PlayersCubit(repository, 'c1'),
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect((cubit.state as PlayersFailed).failure, isA<NetworkFailure>());
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
      when(
        () => repository.currentPlayers('c1'),
      ).thenThrow(const NetworkFailure());
      await cubit.refresh();
    },
    verify: (cubit) {
      expect(cubit.state, isA<PlayersReady>());
      expect((cubit.state as PlayersReady).players, hasLength(1));
    },
  );

  blocTest<PlayersCubit, PlayersState>(
    'an added placeholder lands in name order without a refetch',
    setUp: () {
      stubRoster([_player('p1', 'Ada'), _player('p3', 'Zoe')]);
      when(
        () => repository.addPlaceholder(
          competitionId: any(named: 'competitionId'),
          displayName: any(named: 'displayName'),
        ),
      ).thenAnswer((_) async => _player('p2', 'Grace'));
    },
    build: () => PlayersCubit(repository, 'c1'),
    act: (cubit) async {
      await cubit.load();
      await cubit.addPlaceholder('Grace');
    },
    verify: (cubit) {
      expect(_ready(cubit).players.map((player) => player.displayName), [
        'Ada',
        'Grace',
        'Zoe',
      ]);
      verify(() => repository.currentPlayers('c1')).called(1);
    },
  );

  blocTest<PlayersCubit, PlayersState>(
    'a rename replaces the row and re-sorts it',
    setUp: () {
      stubRoster([_player('p1', 'Ada'), _player('p2', 'Grace')]);
      when(
        () => repository.rename(playerId: 'p1', displayName: 'Zoe'),
      ).thenAnswer((_) async => _player('p1', 'Zoe'));
    },
    build: () => PlayersCubit(repository, 'c1'),
    act: (cubit) async {
      await cubit.load();
      await cubit.rename('p1', 'Zoe');
    },
    verify: (cubit) => expect(
      _ready(cubit).players.map((player) => player.displayName),
      ['Grace', 'Zoe'],
    ),
  );

  blocTest<PlayersCubit, PlayersState>(
    'removing a player moves them out of the active roster',
    setUp: () {
      stubRoster([_player('p1', 'Ada'), _player('p2', 'Grace')]);
      when(
        () => repository.setActive(playerId: 'p2', isActive: false),
      ).thenAnswer((_) async => _player('p2', 'Grace', isActive: false));
    },
    build: () => PlayersCubit(repository, 'c1'),
    act: (cubit) async {
      await cubit.load();
      await cubit.setActive('p2', isActive: false);
    },
    verify: (cubit) {
      expect(_ready(cubit).active.map((player) => player.id), ['p1']);
      expect(_ready(cubit).inactive.map((player) => player.id), ['p2']);
    },
  );

  blocTest<PlayersCubit, PlayersState>(
    'a refused edit is reported without disturbing the roster',
    setUp: () {
      stubRoster([_player('p1', 'Ada')]);
      when(
        () => repository.rename(
          playerId: any(named: 'playerId'),
          displayName: any(named: 'displayName'),
        ),
      ).thenThrow(const PermissionFailure());
    },
    build: () => PlayersCubit(repository, 'c1'),
    act: (cubit) async {
      await cubit.load();
      final ok = await cubit.rename('p1', 'Grace');
      expect(ok, isFalse);
    },
    verify: (cubit) {
      expect(_ready(cubit).actionFailure, isA<PermissionFailure>());
      expect(cubit.state, isA<PlayersReady>());
      expect(_ready(cubit).players.single.displayName, 'Ada');
      expect(_ready(cubit).busy, isFalse);
    },
  );
}
