import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/features/competition/domain/competition.dart';
import 'package:keepscore2/features/competition/domain/competition_repository.dart';
import 'package:keepscore2/features/leaderboard/domain/leaderboard_repository.dart';
import 'package:keepscore2/features/leaderboard/domain/season_window.dart';
import 'package:keepscore2/features/match/domain/match_repository.dart';
import 'package:keepscore2/features/match/presentation/cubit/match_form_cubit.dart';
import 'package:keepscore2/features/match/presentation/pages/new_match_page.dart';
import 'package:keepscore2/features/player/domain/player.dart';
import 'package:keepscore2/features/player/domain/player_repository.dart';
import 'package:keepscore2/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockMatchRepository extends Mock implements MatchRepository {}

class MockCompetitionRepository extends Mock implements CompetitionRepository {}

class MockPlayerRepository extends Mock implements PlayerRepository {}

class MockLeaderboardRepository extends Mock implements LeaderboardRepository {}

Competition _competition() => Competition(
  id: 'c1',
  joinCode: 'HDHS39',
  name: 'Office Table Tennis',
  ownerId: 'u1',
  seasonLength: SeasonLength.monthly,
  timezone: 'Europe/Amsterdam',
  startingRating: 1000,
  kFactor: 32,
  movEnabled: false,
  movCap: 2.5,
  allowDraws: true,
  createdAt: DateTime(2026),
);

Player _player(String id, String name) => Player(
  id: id,
  competitionId: 'c1',
  displayName: name,
  isActive: true,
);

void main() {
  testWidgets(
    'picking players from a team sheet renders them alphabetically inside that team',
    (tester) async {
      final matches = MockMatchRepository();
      final competitions = MockCompetitionRepository();
      final players = MockPlayerRepository();
      final leaderboard = MockLeaderboardRepository();

      when(() => competitions.overview('c1')).thenAnswer(
        (_) async => CompetitionOverview(
          competition: _competition(),
          playerCount: 3,
          matchCount: 0,
        ),
      );
      when(() => players.roster('c1')).thenAnswer(
        (_) async => [
          _player('p1', 'Zoe'),
          _player('p2', 'Ada'),
          _player('p3', 'Mia'),
        ],
      );
      when(() => leaderboard.currentSeason('c1')).thenAnswer(
        (_) async => SeasonWindow(
          id: 's1',
          startsAt: DateTime(2026, 8),
          endsAt: DateTime(2026, 9),
        ),
      );
      when(
        () => leaderboard.standings(competitionId: 'c1', seasonId: 's1'),
      ).thenAnswer((_) async => []);

      final cubit = MatchFormCubit(matches, competitions, players, leaderboard, 'c1');
      addTearDown(cubit.close);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BlocProvider.value(
            value: cubit,
            child: const NewMatchPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('teamAreaA')), findsOneWidget);
      expect(find.byKey(const Key('teamAreaB')), findsOneWidget);

      await tester.tap(find.byKey(const Key('teamAreaA')));
      await tester.pumpAndSettle();

      final sheetNames = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byKey(const Key('teamPickerSheet')),
              matching: find.byType(Text),
            ),
          )
          .map((text) => text.data)
          .whereType<String>()
          .toList();
      final sheetOrder = ['Ada', 'Mia', 'Zoe'].map(sheetNames.indexOf).toList();
      expect(sheetOrder, equals(List.of(sheetOrder)..sort()));

      await tester.tap(find.text('Ada'));
      await tester.tap(find.text('Zoe'));
      final l10n = AppLocalizations.of(
        tester.element(find.byType(NewMatchPage)),
      );
      await tester.tap(find.text(l10n.commonDone));
      await tester.pumpAndSettle();

      final teamAText = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byKey(const Key('teamAreaA')),
              matching: find.byType(Text),
            ),
          )
          .map((text) => text.data)
          .whereType<String>()
          .toList();

      expect(teamAText, containsAllInOrder(['Ada', 'Zoe']));
      expect(teamAText, contains('1000'));

      await tester.tap(find.byKey(const Key('teamAreaB')));
      await tester.pumpAndSettle();

      final otherSheetNames = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byKey(const Key('teamPickerSheet')),
              matching: find.byType(Text),
            ),
          )
          .map((text) => text.data)
          .whereType<String>()
          .toList();

      expect(otherSheetNames, contains('Mia'));
      expect(otherSheetNames, isNot(contains('Ada')));
      expect(otherSheetNames, isNot(contains('Zoe')));
    },
  );
}
