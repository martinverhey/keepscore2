import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/widgets/adaptive/adaptive.dart';
import 'package:keepscore2/features/competition/presentation/widgets/invite_sheet.dart';
import 'package:keepscore2/features/competition/presentation/widgets/join_code_card.dart';
import 'package:keepscore2/features/competition/presentation/widgets/join_qr_card.dart';
import 'package:keepscore2/l10n/app_localizations.dart';

void main() {
  tearDown(() => AppPlatform.debugOverrideCupertino = null);

  for (final useCupertino in [false, true]) {
    testWidgets(
      'shows both the QR and the plain code (cupertino: $useCupertino)',
      (tester) async {
        AppPlatform.debugOverrideCupertino = useCupertino;

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => AdaptiveScaffold(
                title: 'Leaderboard',
                body: AdaptiveButton(
                  label: 'Invite',
                  onPressed: () => showInviteSheet(context, code: 'HDHS39'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Invite'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(JoinQrCard), findsOneWidget);
        expect(find.byType(JoinCodeCard), findsOneWidget);
        expect(find.text('HDHS39'), findsOneWidget);
      },
    );
  }
}
