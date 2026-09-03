import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/features/competition/domain/competition.model.dart';
import 'package:keepscore2/features/leaderboard/domain/leaderboard.model.dart';
import 'package:keepscore2/features/leaderboard/domain/medals.model.dart';
import 'package:keepscore2/features/leaderboard/presentation/widgets/leaderboard_row.dart';
import 'package:keepscore2/l10n/app_localizations.dart';

Leaderboard _leaderboard({
  bool isOwner = false,
  StreakType streakType = StreakType.none,
  int streakCount = 0,
  double todayDelta = 0,
  Medal? medal,
}) => Leaderboard(
  seasonId: 's1',
  competitionId: 'c1',
  playerId: 'p1',
  displayName: 'Ada Lovelace',
  isClaimed: true,
  isOwner: isOwner,
  rating: 1080,
  played: 5,
  wins: 4,
  losses: 1,
  draws: 0,
  rank: 1,
  streakType: streakType,
  streakCount: streakCount,
  todayDelta: todayDelta,
  medal: medal,
);

void main() {
  Future<void> pumpRow(
    WidgetTester tester,
    Leaderboard leaderboard, {
    Medals? medals,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: LeaderboardRow(
              competitionId: 'c1',
              leaderboard: leaderboard,
              isMe: false,
              myPlayerId: null,
              seasonLength: SeasonLength.monthly,
              medals: medals,
              opensProfile: false,
            ),
          ),
        ),
      ),
    );
  }

  Future<double> heightOf(
    WidgetTester tester,
    Leaderboard leaderboard, {
    Medals? medals,
  }) async {
    await pumpRow(tester, leaderboard, medals: medals);
    return tester.getSize(find.byType(LeaderboardRow)).height;
  }

  testWidgets('every row is the same height, whatever it carries', (
    tester,
  ) async {
    final plain = await heightOf(tester, _leaderboard());

    expect(await heightOf(tester, _leaderboard(isOwner: true)), plain);
    expect(await heightOf(tester, _leaderboard(medal: Medal.gold)), plain);
    expect(
      await heightOf(
        tester,
        _leaderboard(),
        medals: const Medals(playerId: 'p1', gold: 2, silver: 1, bronze: 0),
      ),
      plain,
    );
    expect(
      await heightOf(
        tester,
        _leaderboard(streakType: StreakType.win, streakCount: 12),
      ),
      plain,
    );
    expect(await heightOf(tester, _leaderboard(todayDelta: 12.4)), plain);
    expect(
      await heightOf(
        tester,
        _leaderboard(
          isOwner: true,
          streakType: StreakType.win,
          streakCount: 12,
          todayDelta: -12.4,
          medal: Medal.gold,
        ),
        medals: const Medals(playerId: 'p1', gold: 2, silver: 1, bronze: 1),
      ),
      plain,
    );
  });

  testWidgets('the name is centred whenever it carries no medals', (
    tester,
  ) async {
    await pumpRow(tester, _leaderboard());
    expect(
      _offCenter(tester, 'Ada Lovelace'),
      moreOrLessEquals(0, epsilon: 0.5),
    );

    await pumpRow(
      tester,
      _leaderboard(streakType: StreakType.win, streakCount: 12),
    );
    expect(
      _offCenter(tester, 'Ada Lovelace'),
      moreOrLessEquals(0, epsilon: 0.5),
    );
  });

  testWidgets('the rating is centred whenever it carries no badges', (
    tester,
  ) async {
    await pumpRow(tester, _leaderboard());
    expect(_offCenter(tester, '1080'), moreOrLessEquals(0, epsilon: 0.5));

    await pumpRow(
      tester,
      _leaderboard(),
      medals: const Medals(playerId: 'p1', gold: 2, silver: 1, bronze: 0),
    );
    expect(_offCenter(tester, '1080'), moreOrLessEquals(0, epsilon: 0.5));
  });

  testWidgets('a secondary line lifts its own column off centre', (
    tester,
  ) async {
    await pumpRow(
      tester,
      _leaderboard(streakType: StreakType.win, streakCount: 12),
      medals: const Medals(playerId: 'p1', gold: 2, silver: 1, bronze: 0),
    );

    expect(_offCenter(tester, 'Ada Lovelace'), lessThan(-4));
    expect(_offCenter(tester, '1080'), lessThan(-4));
  });
}

double _offCenter(WidgetTester tester, String text) {
  final card = tester.getRect(
    find
        .descendant(
          of: find.byType(LeaderboardRow),
          matching: find.byType(Container),
        )
        .first,
  );
  return tester.getRect(find.text(text)).center.dy - card.center.dy;
}
