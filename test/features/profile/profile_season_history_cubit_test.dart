import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/error/failure.dart';
import 'package:keepscore2/features/leaderboard/domain/leaderboard_repository.dart';
import 'package:keepscore2/features/leaderboard/domain/season_standing.model.dart';
import 'package:keepscore2/features/match/domain/game_type.enum.dart';
import 'package:keepscore2/features/match/presentation/cubit/game_type_filter_cubit.dart';
import 'package:keepscore2/features/profile/presentation/cubit/profile_season_history_cubit.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockLeaderboardRepository extends Mock implements LeaderboardRepository {}

final _july = DateTime.utc(2026, 6, 30, 22);
final _august = DateTime.utc(2026, 7, 31, 22);

SeasonStanding _pastSeason(double rating) => SeasonStanding(
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

  ProfileSeasonHistoryCubit build() => ProfileSeasonHistoryCubit(
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
      () => leaderboardRepository.seasonHistory(
        competitionId: 'c1',
        playerId: 'p1',
        gameType: any(named: 'gameType'),
      ),
    ).thenAnswer((_) async => const []);
  });

  tearDown(() => gameTypeFilterCubit.close());

  blocTest<ProfileSeasonHistoryCubit, ProfileSeasonHistoryState>(
    'loads this player\'s standing in every finished season',
    setUp: () => when(
      () => leaderboardRepository.seasonHistory(
        competitionId: 'c1',
        playerId: 'p1',
        gameType: null,
      ),
    ).thenAnswer((_) async => [_pastSeason(1120)]),
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.status, ProfileSeasonHistoryStatus.ready);
      expect(cubit.state.standings, hasLength(1));
      expect(cubit.state.standings.single.rating, 1120);
    },
  );

  blocTest<ProfileSeasonHistoryCubit, ProfileSeasonHistoryState>(
    'a failed load surfaces the error',
    setUp: () => when(
      () => leaderboardRepository.seasonHistory(
        competitionId: 'c1',
        playerId: 'p1',
        gameType: null,
      ),
    ).thenThrow(const NetworkFailure()),
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.status, ProfileSeasonHistoryStatus.failed);
      expect(cubit.state.failure, isA<NetworkFailure>());
    },
  );

  blocTest<ProfileSeasonHistoryCubit, ProfileSeasonHistoryState>(
    'switching game type refetches the standings for it',
    setUp: () => when(
      () => leaderboardRepository.seasonHistory(
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
      expect(cubit.state.standings.single.rating, 1090);
    },
  );

  blocTest<ProfileSeasonHistoryCubit, ProfileSeasonHistoryState>(
    'reselecting the same game type is a no-op',
    build: build,
    act: (cubit) async {
      await cubit.load();
      await gameTypeFilterCubit.select(null);
      await _settle();
    },
    expect: () => [
      isA<ProfileSeasonHistoryState>(),
      isA<ProfileSeasonHistoryState>(),
    ],
  );

  blocTest<ProfileSeasonHistoryCubit, ProfileSeasonHistoryState>(
    'a slower response for an abandoned game type does not clobber a '
    'faster one for the type selected after it',
    build: build,
    act: (cubit) async {
      await cubit.load();

      final slow = Completer<List<SeasonStanding>>();
      when(
        () => leaderboardRepository.seasonHistory(
          competitionId: 'c1',
          playerId: 'p1',
          gameType: GameType.oneVOne,
        ),
      ).thenAnswer((_) => slow.future);
      when(
        () => leaderboardRepository.seasonHistory(
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
      expect(cubit.state.standings.single.rating, 1010);
    },
  );
}
