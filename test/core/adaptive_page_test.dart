import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:keepscore2/core/widgets/adaptive/adaptive.dart';

GoRouter buildRouter() {
  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const AdaptiveScaffold(
          title: 'Matches',
          body: Text('shell'),
        ),
        routes: [
          GoRoute(
            path: 'modal',
            pageBuilder: (context, state) => adaptiveModalPage<bool>(
              context,
              child: const AdaptiveScaffold(
                title: 'Log a match',
                body: Text('form'),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

void main() {
  tearDown(() => AppPlatform.debugOverrideCupertino = null);

  group('adaptiveModalPage', () {
    testWidgets('offers a close affordance on Material', (tester) async {
      AppPlatform.debugOverrideCupertino = false;
      final router = buildRouter();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      router.push('/modal');
      await tester.pumpAndSettle();

      expect(find.text('form'), findsOneWidget);
      expect(find.byType(CloseButton), findsOneWidget);
      expect(find.byType(BackButton), findsNothing);
    });

    testWidgets('offers a cancel affordance on Cupertino', (tester) async {
      AppPlatform.debugOverrideCupertino = true;
      final router = buildRouter();
      await tester.pumpWidget(CupertinoApp.router(routerConfig: router));

      router.push('/modal');
      await tester.pumpAndSettle();

      expect(find.text('form'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('hands the pop result back to the opener', (tester) async {
      AppPlatform.debugOverrideCupertino = false;
      final router = buildRouter();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      final result = router.push<bool>('/modal');
      await tester.pumpAndSettle();

      router.pop(true);
      await tester.pumpAndSettle();

      expect(await result, isTrue);
    });
  });
}
