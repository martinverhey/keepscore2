import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:keepscore2/core/widgets/adaptive/adaptive.dart';
import 'package:keepscore2/features/competition/domain/competition_repository.dart';
import 'package:keepscore2/features/competition/presentation/cubit/create_competition_cubit.dart';
import 'package:keepscore2/features/competition/presentation/pages/create_competition.page.dart';
import 'package:keepscore2/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockCompetitionRepository extends Mock implements CompetitionRepository {}

Future<void> _pumpHarness(
  WidgetTester tester, {
  required bool suppressesBackButton,
}) async {
  AppPlatform.debugOverrideCupertino = false;

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (_, _, child) => suppressesBackButton
            ? SuppressedBackButtonScope(child: child)
            : child,
        routes: [
          GoRoute(path: '/', builder: (_, _) => const _CompetitionsStub()),
          GoRoute(
            path: '/create',
            builder: (_, _) => BlocProvider(
              create: (_) =>
                  CreateCompetitionCubit(MockCompetitionRepository()),
              child: const CreateCompetitionPage(),
            ),
          ),
        ],
      ),
    ],
  );

  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.text('Create'));
  await tester.pumpAndSettle();
  expect(find.byType(CreateCompetitionPage), findsOneWidget);
}

void main() {
  tearDown(() => AppPlatform.debugOverrideCupertino = null);

  testWidgets('the implied back button is enough where nothing suppresses it', (
    tester,
  ) async {
    await _pumpHarness(tester, suppressesBackButton: false);

    expect(find.byType(BackButton), findsOneWidget);
    expect(find.byType(AdaptiveIconButton), findsNothing);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.byType(_CompetitionsStub), findsOneWidget);
  });

  testWidgets('the sidebar suppresses the implied back button, so the page '
      'carries its own', (tester) async {
    await _pumpHarness(tester, suppressesBackButton: true);

    expect(find.byType(BackButton), findsNothing);

    await tester.tap(find.byType(AdaptiveIconButton));
    await tester.pumpAndSettle();

    expect(find.byType(_CompetitionsStub), findsOneWidget);
    expect(find.byType(CreateCompetitionPage), findsNothing);
  });
}

class _CompetitionsStub extends StatelessWidget {
  const _CompetitionsStub();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () => context.push('/create'),
        child: const Text('Create'),
      ),
    ),
  );
}
