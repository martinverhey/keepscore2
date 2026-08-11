import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/widgets/adaptive/adaptive.dart';
import 'package:keepscore2/features/competition/presentation/widgets/join_qr_card.dart';
import 'package:keepscore2/l10n/app_localizations.dart';

void main() {
  tearDown(() => AppPlatform.debugOverrideCupertino = null);

  for (final useCupertino in [false, true]) {
    testWidgets(
      'renders inside an AdaptiveScaffold body without an intrinsics crash '
      '(cupertino: $useCupertino)',
      (tester) async {
        AppPlatform.debugOverrideCupertino = useCupertino;

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AdaptiveScaffold(
              title: 'Settings',
              body: JoinQrCard(code: 'HDHS39'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(JoinQrCard), findsOneWidget);
      },
    );
  }
}
