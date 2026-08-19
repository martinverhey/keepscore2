import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/error/failure.dart';
import 'package:keepscore2/features/match/domain/match_entry.model.dart';
import 'package:keepscore2/features/match/domain/match_repository.dart';
import 'package:keepscore2/features/profile/domain/head_to_head_record.model.dart';
import 'package:keepscore2/features/profile/domain/profile_repository.dart';
import 'package:keepscore2/features/profile/presentation/cubit/profile_versus_cubit.dart';
import 'package:mocktail/mocktail.dart';

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

void main() {
  late MockProfileRepository profileRepository;
  late MockMatchRepository matchRepository;

  ProfileVersusCubit build() =>
      ProfileVersusCubit(profileRepository, matchRepository, 'p1', 'viewer');

  setUp(() {
    profileRepository = MockProfileRepository();
    matchRepository = MockMatchRepository();
    when(
      () => profileRepository.headToHead(playerId: 'p1', opponentId: 'viewer'),
    ).thenAnswer((_) async => const HeadToHeadRecord.zero());
    when(
      () => matchRepository.recentBetweenPlayers(
        playerId: 'p1',
        opponentId: 'viewer',
      ),
    ).thenAnswer((_) async => const []);
  });

  blocTest<ProfileVersusCubit, ProfileVersusState>(
    'loads the head-to-head tally and recent matches between the two players',
    setUp: () {
      when(
        () =>
            profileRepository.headToHead(playerId: 'p1', opponentId: 'viewer'),
      ).thenAnswer(
        (_) async => const HeadToHeadRecord(wins: 3, losses: 1, draws: 0),
      );
      when(
        () => matchRepository.recentBetweenPlayers(
          playerId: 'p1',
          opponentId: 'viewer',
        ),
      ).thenAnswer((_) async => [_match('m-vs-1')]);
    },
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      final state = cubit.state as ProfileVersusReady;
      expect(state.headToHead.wins, 3);
      expect(state.recentMatches, hasLength(1));
      expect(state.recentMatches.single.id, 'm-vs-1');
    },
  );

  blocTest<ProfileVersusCubit, ProfileVersusState>(
    'a failed load surfaces the error',
    setUp: () => when(
      () => profileRepository.headToHead(playerId: 'p1', opponentId: 'viewer'),
    ).thenThrow(const NetworkFailure()),
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(
        (cubit.state as ProfileVersusFailed).failure,
        isA<NetworkFailure>(),
      );
    },
  );
}
