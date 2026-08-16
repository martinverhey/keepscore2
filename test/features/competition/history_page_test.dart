import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/widgets/adaptive/adaptive.dart';
import 'package:keepscore2/features/auth/domain/auth_repository.dart';
import 'package:keepscore2/features/auth/domain/auth_user.model.dart';
import 'package:keepscore2/features/auth/presentation/cubit/auth_bloc.dart';
import 'package:keepscore2/features/competition/domain/competition.model.dart';
import 'package:keepscore2/features/competition/domain/competition_repository.dart';
import 'package:keepscore2/features/competition/presentation/cubit/competition_detail_cubit.dart';
import 'package:keepscore2/features/competition/presentation/cubit/history_cubit.dart';
import 'package:keepscore2/features/competition/presentation/pages/history.page.dart';
import 'package:keepscore2/features/leaderboard/domain/leaderboard_repository.dart';
import 'package:keepscore2/features/leaderboard/domain/medal.enum.dart';
import 'package:keepscore2/features/leaderboard/domain/season.model.dart';
import 'package:keepscore2/features/leaderboard/domain/season_leaderboard.model.dart';
import 'package:keepscore2/features/leaderboard/presentation/widgets/leaderboard_row.dart';
import 'package:keepscore2/features/leaderboard/presentation/widgets/season_dropdown.dart';
import 'package:keepscore2/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockCompetitionRepository extends Mock implements CompetitionRepository {}

class MockLeaderboardRepository extends Mock implements LeaderboardRepository {}

final _june = DateTime.utc(2026, 5, 31, 22);
final _july = DateTime.utc(2026, 6, 30, 22);
final _august = DateTime.utc(2026, 7, 31, 22);

SeasonLeaderboard _leaderboard({
  required String seasonId,
  required DateTime startsAt,
  required String playerId,
  required String displayName,
  required int rank,
  Medal? medal,
}) => SeasonLeaderboard(
  seasonId: seasonId,
  competitionId: 'c1',
  playerId: playerId,
  displayName: displayName,
  isClaimed: true,
  rating: 1000,
  played: 5,
  wins: 3,
  losses: 2,
  draws: 0,
  rank: rank,
  startsAt: startsAt,
  endsAt: startsAt.add(const Duration(days: 30)),
  medal: medal,
);

CompetitionOverview _overview() => CompetitionOverview(
  competition: Competition(
    id: 'c1',
    joinCode: 'HDHS39',
    name: 'Office Table Tennis',
    ownerId: 'p1',
    seasonLength: SeasonLength.monthly,
    timezone: 'Europe/Amsterdam',
    startingRating: 1000,
    kFactor: 32,
    movEnabled: true,
    movCap: 2.5,
    allowDraws: true,
    createdAt: DateTime.utc(2026, 5, 1),
  ),
  playerCount: 2,
  matchCount: 10,
  myPlayerId: 'p1',
);

void main() {
  testWidgets(
    'keeps the plain title and shows a season dropdown at the top of the '
    'content, using the leaderboard row for each player, and switches '
    'seasons from it',
    (tester) async {
      final auth = MockAuthRepository();
      final competitions = MockCompetitionRepository();
      final leaderboard = MockLeaderboardRepository();

      when(() => auth.currentUser).thenReturn(
        const AuthUser(id: 'p1', displayName: 'Ada', isGuest: false),
      );
      when(() => auth.watchUser()).thenAnswer((_) => const Stream.empty());

      when(
        () => competitions.overview('c1'),
      ).thenAnswer((_) async => _overview());
      when(() => leaderboard.finishedSeasons('c1')).thenAnswer(
        (_) async => [
          Season(id: 's-july', startsAt: _july, endsAt: _august),
          Season(id: 's-june', startsAt: _june, endsAt: _july),
        ],
      );
      when(
        () => leaderboard.history(competitionId: 'c1', seasonId: 's-july'),
      ).thenAnswer(
        (_) async => [
          _leaderboard(
            seasonId: 's-july',
            startsAt: _july,
            playerId: 'p2',
            displayName: 'Bram',
            rank: 1,
            medal: Medal.gold,
          ),
        ],
      );
      when(
        () => leaderboard.history(competitionId: 'c1', seasonId: 's-june'),
      ).thenAnswer(
        (_) async => [
          _leaderboard(
            seasonId: 's-june',
            startsAt: _june,
            playerId: 'p1',
            displayName: 'Ada',
            rank: 1,
          ),
          _leaderboard(
            seasonId: 's-june',
            startsAt: _june,
            playerId: 'p2',
            displayName: 'Bram',
            rank: 2,
          ),
        ],
      );

      final competitionDetailCubit = CompetitionDetailCubit(competitions, 'c1');
      final historyCubit = HistoryCubit(leaderboard, 'c1');
      final authBloc = AuthBloc(auth);
      addTearDown(competitionDetailCubit.close);
      addTearDown(historyCubit.close);
      addTearDown(authBloc.close);

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: competitionDetailCubit),
            BlocProvider.value(value: historyCubit),
            BlocProvider.value(value: authBloc),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const HistoryPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(HistoryPage)),
      );

      // SliverAppBar.large mounts the title widget for both its collapsed
      // and expanded states at once, so the plain title is legitimately
      // found twice — the dropdown itself, in the content below it, isn't.
      expect(find.text(l10n.historyTitle), findsWidgets);
      expect(find.text(l10n.leaderboardPickSeason), findsNothing);
      expect(find.byType(SeasonDropdown), findsOneWidget);
      expect(find.text('July 2026'), findsOneWidget);

      expect(find.byType(LeaderboardRow), findsOneWidget);
      expect(find.text('Bram'), findsOneWidget);
      expect(find.text(l10n.playersYou), findsNothing);
      expect(
        find.descendant(
          of: find.byType(LeaderboardRow),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is AdaptiveIcon && widget.glyph == AdaptiveGlyph.medal,
          ),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byType(SeasonDropdown));
      await tester.pumpAndSettle();

      expect(find.text(l10n.leaderboardPickSeason), findsOneWidget);
      expect(find.text('June 2026'), findsOneWidget);

      await tester.tap(find.text('June 2026'));
      await tester.pumpAndSettle();

      expect(find.text('July 2026'), findsNothing);
      expect(find.byType(LeaderboardRow), findsNWidgets(2));
      expect(find.text('Ada'), findsOneWidget);
      expect(find.text('Bram'), findsOneWidget);
      expect(find.text(l10n.playersYou), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
