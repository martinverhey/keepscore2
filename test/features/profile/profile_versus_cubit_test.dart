import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/error/failure.dart';
import 'package:keepscore2/features/match/domain/game_type.enum.dart';
import 'package:keepscore2/features/match/domain/match_entry.model.dart';
import 'package:keepscore2/features/match/domain/match_repository.dart';
import 'package:keepscore2/features/match/presentation/cubit/game_type_filter_cubit.dart';
import 'package:keepscore2/features/profile/domain/head_to_head_record.model.dart';
import 'package:keepscore2/features/profile/domain/profile_repository.dart';
import 'package:keepscore2/features/profile/presentation/cubit/profile_versus_cubit.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockMatchRepository extends Mock implements MatchRepository {}

final _august = DateTime.utc(2026, 7, 31, 22);

MatchEntry _match(String id) => MatchEntry(
  id: id,
  competitionId: 'c1',
  seasonId: 's-august',
  playedAt: _august,
  teamAScore: 3,
  teamBScore: 1,
  teamARating: 1040,
  teamBRating: 960,
  teamA: const [],
  teamB: const [],
);

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late MockProfileRepository profileRepository;
  late MockMatchRepository matchRepository;
  late GameTypeFilterCubit gameTypeFilterCubit;

  ProfileVersusCubit build() => ProfileVersusCubit(
    profileRepository,
    matchRepository,
    gameTypeFilterCubit,
    'p1',
    'viewer',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    profileRepository = MockProfileRepository();
    matchRepository = MockMatchRepository();
    gameTypeFilterCubit = GameTypeFilterCubit();
    when(
      () => profileRepository.headToHead(playerId: 'p1', opponentId: 'viewer'),
    ).thenAnswer((_) async => const []);
    when(
      () => matchRepository.recentBetweenPlayers(
        playerId: 'p1',
        opponentId: 'viewer',
        gameType: any(named: 'gameType'),
      ),
    ).thenAnswer((_) async => const []);
  });

  tearDown(() => gameTypeFilterCubit.close());

  blocTest<ProfileVersusCubit, ProfileVersusState>(
    'loads the head-to-head tally and recent matches between the two players',
    setUp: () {
      when(
        () =>
            profileRepository.headToHead(playerId: 'p1', opponentId: 'viewer'),
      ).thenAnswer(
        (_) async => const [
          HeadToHeadRecord(
            gameType: GameType.oneVOne,
            wins: 3,
            losses: 1,
            draws: 0,
          ),
        ],
      );
      when(
        () => matchRepository.recentBetweenPlayers(
          playerId: 'p1',
          opponentId: 'viewer',
          gameType: null,
        ),
      ).thenAnswer((_) async => [_match('m-vs-1')]);
    },
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.status, ProfileVersusStatus.ready);
      expect(cubit.state.headToHead, hasLength(1));
      expect(cubit.state.headToHead.single.wins, 3);
      expect(cubit.state.recentMatches, hasLength(1));
      expect(cubit.state.recentMatches.single.id, 'm-vs-1');
    },
  );

  blocTest<ProfileVersusCubit, ProfileVersusState>(
    'a failed load surfaces the error',
    setUp: () => when(
      () =>
          profileRepository.headToHead(playerId: 'p1', opponentId: 'viewer'),
    ).thenThrow(const NetworkFailure()),
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.status, ProfileVersusStatus.failed);
      expect(cubit.state.failure, isA<NetworkFailure>());
    },
  );

  blocTest<ProfileVersusCubit, ProfileVersusState>(
    'switching game type refetches just the recent matches, not the '
    'head-to-head tally, and filters the tally client-side',
    setUp: () {
      when(
        () =>
            profileRepository.headToHead(playerId: 'p1', opponentId: 'viewer'),
      ).thenAnswer(
        (_) async => const [
          HeadToHeadRecord(
            gameType: GameType.oneVOne,
            wins: 3,
            losses: 1,
            draws: 0,
          ),
          HeadToHeadRecord(
            gameType: GameType.twoVTwo,
            wins: 1,
            losses: 0,
            draws: 1,
          ),
        ],
      );
      when(
        () => matchRepository.recentBetweenPlayers(
          playerId: 'p1',
          opponentId: 'viewer',
          gameType: GameType.oneVOne,
        ),
      ).thenAnswer((_) async => [_match('m-1v1')]);
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      await gameTypeFilterCubit.select(GameType.oneVOne);
      await _settle();
    },
    verify: (cubit) {
      expect(cubit.state.recentMatches.single.id, 'm-1v1');
      expect(cubit.state.records, hasLength(1));
      expect(cubit.state.records.single.wins, 3);
      verify(
        () => profileRepository.headToHead(
          playerId: 'p1',
          opponentId: 'viewer',
        ),
      ).called(1);
    },
  );

  blocTest<ProfileVersusCubit, ProfileVersusState>(
    'a slower response for an abandoned game type does not clobber a '
    'faster one for the type selected after it',
    build: build,
    act: (cubit) async {
      await cubit.load();

      final slow = Completer<List<MatchEntry>>();
      when(
        () => matchRepository.recentBetweenPlayers(
          playerId: 'p1',
          opponentId: 'viewer',
          gameType: GameType.oneVOne,
        ),
      ).thenAnswer((_) => slow.future);
      when(
        () => matchRepository.recentBetweenPlayers(
          playerId: 'p1',
          opponentId: 'viewer',
          gameType: GameType.twoVTwo,
        ),
      ).thenAnswer((_) async => [_match('m-2v2')]);

      unawaited(gameTypeFilterCubit.select(GameType.oneVOne));
      await _settle();
      await gameTypeFilterCubit.select(GameType.twoVTwo);
      await _settle();

      slow.complete([_match('m-1v1')]);
      await _settle();
    },
    verify: (cubit) {
      expect(cubit.state.selectedGameType, GameType.twoVTwo);
      expect(cubit.state.recentMatches.single.id, 'm-2v2');
    },
  );
}
