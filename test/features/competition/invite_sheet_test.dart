import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/widgets/adaptive/adaptive.dart';
import 'package:keepscore2/features/competition/domain/competition.model.dart';
import 'package:keepscore2/features/competition/presentation/pages/invite_sheet.dart';
import 'package:keepscore2/features/competition/presentation/widgets/active_competition_card.dart';
import 'package:keepscore2/features/competition/presentation/widgets/join_code_tag.dart';
import 'package:keepscore2/features/competition/presentation/widgets/join_qr_image.dart';
import 'package:keepscore2/l10n/app_localizations.dart';

CompetitionOverview _overview() => CompetitionOverview(
  competition: Competition(
    id: 'c1',
    joinCode: 'HDHS39',
    name: 'Office Table Tennis',
    ownerId: 'user-1',
    seasonLength: SeasonLength.monthly,
    timezone: 'Europe/Amsterdam',
    startingRating: 1000,
    kFactor: 32,
    movEnabled: true,
    movCap: 2.5,
    allowDraws: true,
    createdAt: DateTime.utc(2026, 8, 9),
  ),
  playerCount: 5,
  matchCount: 11,
);

Future<void> _openSheet(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => AdaptiveScaffold(
          title: 'Leaderboard',
          body: AdaptiveButton(
            label: 'Invite',
            onPressed: () => showInviteSheet(context, overview: _overview()),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('Invite'));
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() => AppPlatform.debugOverrideCupertino = null);

  for (final useCupertino in [false, true]) {
    testWidgets('shows the competition card without its open affordances '
        '(cupertino: $useCupertino)', (tester) async {
      AppPlatform.debugOverrideCupertino = useCupertino;

      await _openSheet(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(ActiveCompetitionCard), findsOneWidget);
      expect(find.byType(JoinQrImage), findsOneWidget);
      expect(find.text('Office Table Tennis'), findsOneWidget);
      expect(find.text('HDHS39'), findsOneWidget);
      expect(find.text('Active competition'), findsNothing);
      expect(find.text('Manage'), findsNothing);
      final name = tester.getRect(find.text('Office Table Tennis'));
      final code = tester.getRect(find.byType(JoinCodeTag));
      expect(code.top, closeTo(name.top, 4));
      expect(code.left, greaterThanOrEqualTo(name.right));
      expect(
        find.descendant(
          of: find.byType(ActiveCompetitionCard),
          matching: find.byType(AdaptiveIcon),
        ),
        findsNothing,
      );
    });
  }

  testWidgets('copies the join code when the code is tapped', (tester) async {
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await _openSheet(tester);
    await tester.tap(find.byType(JoinCodeTag));
    await tester.pumpAndSettle();

    expect(copied, ['HDHS39']);
    expect(find.text('Copied'), findsOneWidget);
    expect(find.text('HDHS39'), findsNothing);

    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Copied'), findsNothing);
    expect(find.text('HDHS39'), findsOneWidget);
  });
}
