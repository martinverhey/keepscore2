import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/error/failure.dart';
import 'package:keepscore2/features/match/domain/match_entry.dart';
import 'package:keepscore2/features/match/domain/match_repository.dart';
import 'package:keepscore2/features/match/presentation/cubit/match_list_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockMatchRepository extends Mock implements MatchRepository {}

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

void main() {
  late MockMatchRepository repository;
  late StreamController<void> ticks;

  setUp(() {
    repository = MockMatchRepository();
    ticks = StreamController<void>();
    when(() => repository.watch('c1')).thenAnswer((_) => ticks.stream);
  });

  tearDown(() => ticks.close());

  void stubPage(List<MatchEntry> matches, {int offset = 0}) {
    when(
      () => repository.feed(
        competitionId: 'c1',
        limit: MatchListCubit.pageSize,
        offset: offset,
      ),
    ).thenAnswer((_) async => matches);
  }

  blocTest<MatchListCubit, MatchListState>(
    'a short first page means there is nothing more to fetch',
    setUp: () => stubPage(_page(3)),
    build: () => MatchListCubit(repository, 'c1'),
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.status, MatchListStatus.ready);
      expect(cubit.state.matches, hasLength(3));
      expect(cubit.state.hasMore, isFalse);
    },
  );

  blocTest<MatchListCubit, MatchListState>(
    'a full page leaves the door open for another',
    setUp: () => stubPage(_page(MatchListCubit.pageSize)),
    build: () => MatchListCubit(repository, 'c1'),
    act: (cubit) => cubit.load(),
    verify: (cubit) => expect(cubit.state.hasMore, isTrue),
  );

  blocTest<MatchListCubit, MatchListState>(
    'loading more appends to the list',
    setUp: () {
      stubPage(_page(MatchListCubit.pageSize));
      stubPage(_page(2, from: 100), offset: MatchListCubit.pageSize);
    },
    build: () => MatchListCubit(repository, 'c1'),
    act: (cubit) async {
      await cubit.load();
      await cubit.loadMore();
    },
    verify: (cubit) {
      expect(cubit.state.matches, hasLength(MatchListCubit.pageSize + 2));
      expect(cubit.state.hasMore, isFalse);
      expect(cubit.state.loadingMore, isFalse);
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
    build: () => MatchListCubit(repository, 'c1'),
    act: (cubit) async {
      await cubit.load();
      await cubit.loadMore();
    },
    verify: (cubit) {
      expect(cubit.state.status, MatchListStatus.ready);
      expect(cubit.state.matches, hasLength(MatchListCubit.pageSize));
      expect(cubit.state.actionFailure, isA<NetworkFailure>());
      expect(cubit.state.failure, isNull);
    },
  );

  blocTest<MatchListCubit, MatchListState>(
    'a match logged elsewhere pulls the feed in without a gesture',
    setUp: () => stubPage(_page(1)),
    build: () => MatchListCubit(repository, 'c1'),
    act: (cubit) async {
      await cubit.load();
      stubPage(_page(2));
      ticks.add(null);
    },
    wait: const Duration(milliseconds: 600),
    verify: (cubit) => expect(cubit.state.matches, hasLength(2)),
  );

  blocTest<MatchListCubit, MatchListState>(
    'a burst of ticks from one season replay refetches once',
    setUp: () => stubPage(_page(1)),
    build: () => MatchListCubit(repository, 'c1'),
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
    build: () => MatchListCubit(repository, 'c1'),
    act: (cubit) async {
      await cubit.load();
      await cubit.loadMore();
      await cubit.refresh();
    },
    verify: (cubit) =>
        expect(cubit.state.matches, hasLength(MatchListCubit.pageSize + 5)),
  );

  blocTest<MatchListCubit, MatchListState>(
    'a silent refresh keeps the current list when the refetch fails',
    setUp: () => stubPage(_page(2)),
    build: () => MatchListCubit(repository, 'c1'),
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
      expect(cubit.state.status, MatchListStatus.failed);
      expect(cubit.state.matches, hasLength(2));
    },
  );
}
