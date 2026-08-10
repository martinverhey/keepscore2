import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:keepscore2/app/router/app_router.dart';
import 'package:keepscore2/core/widgets/adaptive/adaptive.dart';
import 'package:keepscore2/features/auth/presentation/widgets/guest_notice.dart';
import 'package:keepscore2/l10n/app_localizations.dart';

void main() {
  tearDown(() => AppPlatform.debugOverrideCupertino = null);

  testWidgets('a guest is offered a way out, not just a refusal',
      (tester) async {
    AppPlatform.debugOverrideCupertino = false;

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(
            body: GuestNotice(message: 'Guests may not log matches'),
          ),
        ),
        GoRoute(
          path: Routes.upgradeAccount,
          builder: (_, _) => const Scaffold(body: Text('upgrade')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );

    expect(find.text('Guests may not log matches'), findsOneWidget);
    expect(find.text('Guest'), findsOneWidget);

    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();

    expect(find.text('upgrade'), findsOneWidget);
  });
}
