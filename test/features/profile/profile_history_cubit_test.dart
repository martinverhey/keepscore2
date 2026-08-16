import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/error/failure.dart';
import 'package:keepscore2/features/leaderboard/domain/leaderboard_repository.dart';
import 'package:keepscore2/features/leaderboard/domain/season_leaderboard.model.dart';
import 'package:keepscore2/features/match/domain/game_type.enum.dart';
import 'package:keepscore2/features/match/presentation/cubit/game_type_filter_cubit.dart';
import 'package:keepscore2/features/profile/presentation/cubit/profile_history_cubit.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockLeaderboardRepository extends Mock implements LeaderboardRepository {}

final _july = DateTime.utc(2026, 6, 30, 22);
final _august = DateTime.utc(2026, 7, 31, 22);

SeasonLeaderboard _pastSeason(double rating) => SeasonLeaderboard(
  seasonId: 's-july',
  competitionId: 'c1',
  playerId: 'p1',
  displayName: 'p1',
  isClaimed: true,
  rating: rating,
  played: 5,
  wins: 4,
  losses: 1,
  draws: 0,
  rank: 1,
  startsAt: _july,
  endsAt: _august,
  medal: null,
);

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late MockLeaderboardRepository leaderboardRepository;
  late GameTypeFilterCubit gameTypeFilterCubit;

  ProfileHistoryCubit build() => ProfileHistoryCubit(
    leaderboardRepository,
    gameTypeFilterCubit,
    'c1',
    'p1',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    leaderboardRepository = MockLeaderboardRepository();
    gameTypeFilterCubit = GameTypeFilterCubit();
    when(
      () => leaderboardRepository.history(
        competitionId: 'c1',
        playerId: 'p1',
        gameType: any(named: 'gameType'),
      ),
    ).thenAnswer((_) async => const []);
  });

  tearDown(() => gameTypeFilterCubit.close());

  blocTest<ProfileHistoryCubit, ProfileHistoryState>(
    'loads this player\'s leaderboard entry in every finished season',
    setUp: () => when(
      () => leaderboardRepository.history(
        competitionId: 'c1',
        playerId: 'p1',
        gameType: null,
      ),
    ).thenAnswer((_) async => [_pastSeason(1120)]),
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.status, ProfileHistoryStatus.ready);
      expect(cubit.state.leaderboards, hasLength(1));
      expect(cubit.state.leaderboards.single.rating, 1120);
    },
  );

  blocTest<ProfileHistoryCubit, ProfileHistoryState>(
    'a failed load surfaces the error',
    setUp: () => when(
      () => leaderboardRepository.history(
        competitionId: 'c1',
        playerId: 'p1',
        gameType: null,
      ),
    ).thenThrow(const NetworkFailure()),
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.status, ProfileHistoryStatus.failed);
      expect(cubit.state.failure, isA<NetworkFailure>());
    },
  );

  blocTest<ProfileHistoryCubit, ProfileHistoryState>(
    'switching game type refetches the leaderboards for it',
    setUp: () => when(
      () => leaderboardRepository.history(
        competitionId: 'c1',
        playerId: 'p1',
        gameType: GameType.oneVOne,
      ),
    ).thenAnswer((_) async => [_pastSeason(1090)]),
    build: build,
    act: (cubit) async {
      await cubit.load();
      await gameTypeFilterCubit.select(GameType.oneVOne);
      await _settle();
    },
    verify: (cubit) {
      expect(cubit.state.selectedGameType, GameType.oneVOne);
      expect(cubit.state.leaderboards.single.rating, 1090);
    },
  );

  blocTest<ProfileHistoryCubit, ProfileHistoryState>(
    'reselecting the same game type is a no-op',
    build: build,
    act: (cubit) async {
      await cubit.load();
      await gameTypeFilterCubit.select(null);
      await _settle();
    },
    expect: () => [isA<ProfileHistoryState>(), isA<ProfileHistoryState>()],
  );

  blocTest<ProfileHistoryCubit, ProfileHistoryState>(
    'a slower response for an abandoned game type does not clobber a '
    'faster one for the type selected after it',
    build: build,
    act: (cubit) async {
      await cubit.load();

      final slow = Completer<List<SeasonLeaderboard>>();
      when(
        () => leaderboardRepository.history(
          competitionId: 'c1',
          playerId: 'p1',
          gameType: GameType.oneVOne,
        ),
      ).thenAnswer((_) => slow.future);
      when(
        () => leaderboardRepository.history(
          competitionId: 'c1',
          playerId: 'p1',
          gameType: GameType.twoVTwo,
        ),
      ).thenAnswer((_) async => [_pastSeason(1010)]);

      unawaited(gameTypeFilterCubit.select(GameType.oneVOne));
      await _settle();
      await gameTypeFilterCubit.select(GameType.twoVTwo);
      await _settle();

      slow.complete([_pastSeason(1090)]);
      await _settle();
    },
    verify: (cubit) {
      expect(cubit.state.selectedGameType, GameType.twoVTwo);
      expect(cubit.state.leaderboards.single.rating, 1010);
    },
  );
}
