import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/error/failure.dart';
import 'package:keepscore2/features/match/domain/game_type.enum.dart';
import 'package:keepscore2/features/match/domain/match_entry.model.dart';
import 'package:keepscore2/features/match/domain/match_repository.dart';
import 'package:keepscore2/features/match/presentation/cubit/game_type_filter_cubit.dart';
import 'package:keepscore2/features/match/presentation/cubit/match_list_cubit.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockMatchRepository extends Mock implements MatchRepository {}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

MatchEntry _match(String id) => MatchEntry(
  id: id,
  competitionId: 'c1',
  seasonId: 's1',
  playedAt: DateTime(2026, 8, 9, 20),
  teamAScore: 11,
  teamBScore: 7,
  teamARating: 1000,
  teamBRating: 1000,
  teamA: const [],
  teamB: const [],
);

List<MatchEntry> _page(int count, {int from = 0}) => [
  for (var i = 0; i < count; i++) _match('m${from + i}'),
];

MatchListReady _ready(MatchListCubit cubit) => cubit.state as MatchListReady;

void main() {
  late MockMatchRepository repository;
  late GameTypeFilterCubit gameTypeFilterCubit;
  late StreamController<void> ticks;

  MatchListCubit build() =>
      MatchListCubit(repository, gameTypeFilterCubit, 'c1');

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = MockMatchRepository();
    gameTypeFilterCubit = GameTypeFilterCubit();
    ticks = StreamController<void>();
    when(() => repository.watch('c1')).thenAnswer((_) => ticks.stream);
    when(
      () => repository.seasonGameTypes('c1'),
    ).thenAnswer((_) async => const <GameType>{});
  });

  tearDown(() {
    ticks.close();
    gameTypeFilterCubit.close();
  });

  void stubPage(List<MatchEntry> matches, {int offset = 0}) {
    when(
      () => repository.feed(
        competitionId: 'c1',
        limit: MatchListCubit.pageSize,
        offset: offset,
      ),
    ).thenAnswer((_) async => matches);
  }

  void stubGameTypePage(GameType gameType, List<MatchEntry> matches) {
    when(
      () => repository.feed(
        competitionId: 'c1',
        gameType: gameType,
        limit: MatchListCubit.pageSize,
      ),
    ).thenAnswer((_) async => matches);
  }

  blocTest<MatchListCubit, MatchListState>(
    'a short first page means there is nothing more to fetch',
    setUp: () => stubPage(_page(3)),
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(_ready(cubit).matches, hasLength(3));
      expect(_ready(cubit).hasMore, isFalse);
    },
  );

  blocTest<MatchListCubit, MatchListState>(
    'a full page leaves the door open for another',
    setUp: () => stubPage(_page(MatchListCubit.pageSize)),
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) => expect(_ready(cubit).hasMore, isTrue),
  );

  blocTest<MatchListCubit, MatchListState>(
    'loading more appends to the list',
    setUp: () {
      stubPage(_page(MatchListCubit.pageSize));
      stubPage(_page(2, from: 100), offset: MatchListCubit.pageSize);
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.loadMore();
    },
    verify: (cubit) {
      expect(_ready(cubit).matches, hasLength(MatchListCubit.pageSize + 2));
      expect(_ready(cubit).hasMore, isFalse);
      expect(_ready(cubit).loadingMore, isFalse);
    },
  );

  blocTest<MatchListCubit, MatchListState>(
    'a failed load more keeps the list and reports separately',
    setUp: () {
      stubPage(_page(MatchListCubit.pageSize));
      when(
        () => repository.feed(
          competitionId: 'c1',
          limit: MatchListCubit.pageSize,
          offset: MatchListCubit.pageSize,
        ),
      ).thenThrow(const NetworkFailure());
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.loadMore();
    },
    verify: (cubit) {
      expect(_ready(cubit).matches, hasLength(MatchListCubit.pageSize));
      expect(_ready(cubit).actionFailure, isA<NetworkFailure>());
    },
  );

  blocTest<MatchListCubit, MatchListState>(
    'a match logged elsewhere pulls the feed in without a gesture',
    setUp: () => stubPage(_page(1)),
    build: build,
    act: (cubit) async {
      await cubit.load();
      stubPage(_page(2));
      ticks.add(null);
    },
    wait: const Duration(milliseconds: 600),
    verify: (cubit) => expect(_ready(cubit).matches, hasLength(2)),
  );

  blocTest<MatchListCubit, MatchListState>(
    'a burst of ticks from one season replay refetches once',
    setUp: () => stubPage(_page(1)),
    build: build,
    act: (cubit) async {
      await cubit.load();
      for (var i = 0; i < 12; i++) {
        ticks.add(null);
      }
    },
    wait: const Duration(milliseconds: 600),
    verify: (cubit) => verify(
      () => repository.feed(
        competitionId: 'c1',
        limit: MatchListCubit.pageSize,
        offset: 0,
      ),
    ).called(2),
  );

  blocTest<MatchListCubit, MatchListState>(
    'a refresh keeps the pages already on screen',
    setUp: () {
      stubPage(_page(MatchListCubit.pageSize));
      stubPage(_page(5, from: 100), offset: MatchListCubit.pageSize);
      when(
        () => repository.feed(
          competitionId: 'c1',
          limit: MatchListCubit.pageSize + 5,
          offset: 0,
        ),
      ).thenAnswer((_) async => _page(MatchListCubit.pageSize + 5));
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.loadMore();
      await cubit.refresh();
    },
    verify: (cubit) =>
        expect(_ready(cubit).matches, hasLength(MatchListCubit.pageSize + 5)),
  );

  blocTest<MatchListCubit, MatchListState>(
    'a silent refresh keeps the current list when the refetch fails',
    setUp: () => stubPage(_page(2)),
    build: build,
    act: (cubit) async {
      await cubit.load();
      when(
        () => repository.feed(
          competitionId: 'c1',
          limit: MatchListCubit.pageSize,
          offset: 0,
        ),
      ).thenThrow(const NetworkFailure());
      await cubit.refresh();
    },
    verify: (cubit) {
      expect(cubit.state, isA<MatchListReady>());
      expect(_ready(cubit).matches, hasLength(2));
    },
  );

  blocTest<MatchListCubit, MatchListState>(
    'loading also reports which game types the season has seen',
    setUp: () {
      stubPage(_page(3));
      when(() => repository.seasonGameTypes('c1')).thenAnswer(
        (_) async => const {GameType.oneVOne, GameType.threeVThree},
      );
    },
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(_ready(cubit).seasonGameTypes, {
        GameType.oneVOne,
        GameType.threeVThree,
      });
    },
  );

  blocTest<MatchListCubit, MatchListState>(
    'switching filter keeps the season\'s game types',
    setUp: () {
      stubPage(_page(3));
      stubGameTypePage(GameType.oneVOne, _page(1, from: 100));
      when(
        () => repository.seasonGameTypes('c1'),
      ).thenAnswer((_) async => const {GameType.oneVOne});
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.selectGameTypeFilter(GameType.oneVOne);
      await _settle();
    },
    verify: (cubit) {
      expect(_ready(cubit).seasonGameTypes, {GameType.oneVOne});
    },
  );

  blocTest<MatchListCubit, MatchListState>(
    'filtering by game type fetches that game type\'s matches',
    setUp: () {
      stubPage(_page(3));
      stubGameTypePage(GameType.oneVOne, _page(1, from: 100));
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.selectGameTypeFilter(GameType.oneVOne);
      await _settle();
    },
    verify: (cubit) {
      expect(_ready(cubit).selectedGameType, GameType.oneVOne);
      expect(_ready(cubit).matches, hasLength(1));
      expect(_ready(cubit).matches.single.id, 'm100');
      expect(_ready(cubit).busy, isFalse);
    },
  );

  blocTest<MatchListCubit, MatchListState>(
    'clearing the game type filter goes back to the combined feed',
    setUp: () {
      stubPage(_page(3));
      stubGameTypePage(GameType.oneVOne, _page(1, from: 100));
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.selectGameTypeFilter(GameType.oneVOne);
      await _settle();
      await cubit.selectGameTypeFilter(null);
      await _settle();
    },
    verify: (cubit) {
      expect(_ready(cubit).selectedGameType, isNull);
      expect(_ready(cubit).matches, hasLength(3));
    },
  );

  blocTest<MatchListCubit, MatchListState>(
    'loading hydrates the filter from the last remembered game type',
    setUp: () async {
      SharedPreferences.setMockInitialValues({'selected_game_type': '2v2'});
      await gameTypeFilterCubit.load();
      stubGameTypePage(GameType.twoVTwo, _page(1, from: 100));
    },
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(_ready(cubit).selectedGameType, GameType.twoVTwo);
      expect(_ready(cubit).matches, hasLength(1));
    },
  );

  blocTest<MatchListCubit, MatchListState>(
    'a game type selected elsewhere (e.g. on the profile page) is picked up immediately',
    setUp: () {
      stubPage(_page(3));
      stubGameTypePage(GameType.oneVOne, _page(1, from: 100));
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      await gameTypeFilterCubit.select(GameType.oneVOne);
      await _settle();
    },
    verify: (cubit) {
      expect(_ready(cubit).selectedGameType, GameType.oneVOne);
      expect(_ready(cubit).matches, hasLength(1));
      expect(_ready(cubit).matches.single.id, 'm100');
    },
  );
}
