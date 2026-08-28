import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/features/auth/domain/auth_repository.dart';
import 'package:keepscore2/features/auth/domain/auth_user.model.dart';
import 'package:keepscore2/features/auth/presentation/cubit/auth_bloc.dart';
import 'package:keepscore2/features/competition/domain/competition.model.dart';
import 'package:keepscore2/features/competition/domain/competition_repository.dart';
import 'package:keepscore2/features/competition/presentation/cubit/competition_cubit.dart';
import 'package:keepscore2/features/leaderboard/domain/leaderboard_repository.dart';
import 'package:keepscore2/features/leaderboard/domain/season_window.model.dart';
import 'package:keepscore2/features/match/domain/match_repository.dart';
import 'package:keepscore2/features/match/presentation/cubit/match_form_cubit.dart';
import 'package:keepscore2/features/match/presentation/pages/new_match_keys.enum.dart';
import 'package:keepscore2/features/match/presentation/pages/new_match.page.dart';
import 'package:keepscore2/features/player/domain/player.model.dart';
import 'package:keepscore2/features/player/domain/player_repository.dart';
import 'package:keepscore2/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

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

Player _player(String id, String name) =>
    Player(id: id, competitionId: 'c1', displayName: name, isActive: true);

void main() {
  testWidgets(
    'picking players from a team sheet renders them alphabetically inside that team',
    (tester) async {
      final auth = MockAuthRepository();
      final matches = MockMatchRepository();
      final competitions = MockCompetitionRepository();
      final players = MockPlayerRepository();
      final leaderboard = MockLeaderboardRepository();

      when(() => auth.currentUser).thenReturn(
        const AuthUser(id: 'u1', displayName: 'Ada', isGuest: false),
      );
      when(() => auth.watchUser()).thenAnswer((_) => const Stream.empty());

      when(() => competitions.overview('c1')).thenAnswer(
        (_) async => CompetitionOverview(
          competition: _competition(),
          playerCount: 3,
          matchCount: 0,
        ),
      );
      when(() => players.currentPlayers('c1')).thenAnswer(
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
        () => leaderboard.leaderboards(competitionId: 'c1', seasonId: 's1'),
      ).thenAnswer((_) async => []);

      final cubit = MatchFormCubit(
        matches,
        competitions,
        players,
        leaderboard,
        'c1',
      );
      final authBloc = AuthBloc(auth);
      final competitionDetailCubit = CompetitionCubit(competitions, authBloc)
        ..select('c1');
      addTearDown(cubit.close);
      addTearDown(authBloc.close);
      addTearDown(competitionDetailCubit.close);

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: cubit),
            BlocProvider.value(value: authBloc),
            BlocProvider.value(value: competitionDetailCubit),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const NewMatchPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey(NewMatchKey.teamAreaA)), findsOneWidget);
      expect(find.byKey(const ValueKey(NewMatchKey.teamAreaB)), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey(NewMatchKey.teamAreaA)));
      await tester.pumpAndSettle();

      final sheetNames = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byKey(const ValueKey(NewMatchKey.teamPickerSheet)),
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
              of: find.byKey(const ValueKey(NewMatchKey.teamAreaA)),
              matching: find.byType(Text),
            ),
          )
          .map((text) => text.data)
          .whereType<String>()
          .toList();

      expect(teamAText, containsAllInOrder(['Ada', 'Zoe']));
      expect(teamAText, contains('1000'));

      await tester.tap(find.byKey(const ValueKey(NewMatchKey.teamAreaB)));
      await tester.pumpAndSettle();

      final otherSheetNames = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byKey(const ValueKey(NewMatchKey.teamPickerSheet)),
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
