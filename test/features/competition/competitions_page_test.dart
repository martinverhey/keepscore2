import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:keepscore2/features/auth/domain/auth_repository.dart';
import 'package:keepscore2/features/auth/domain/auth_user.model.dart';
import 'package:keepscore2/features/auth/presentation/cubit/auth_bloc.dart';
import 'package:keepscore2/features/competition/domain/competition_repository.dart';
import 'package:keepscore2/features/competition/presentation/cubit/competition_cubit.dart';
import 'package:keepscore2/features/competition/presentation/cubit/competition_list_cubit.dart';
import 'package:keepscore2/features/competition/presentation/pages/competitions.page.dart';
import 'package:keepscore2/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockCompetitionRepository extends Mock implements CompetitionRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockCompetitionRepository competitions;
  late MockAuthRepository auth;
  late CompetitionListCubit competitionListCubit;
  late AuthBloc authBloc;
  late CompetitionCubit competitionCubit;

  setUp(() {
    competitions = MockCompetitionRepository();
    auth = MockAuthRepository();

    when(() => competitions.myCompetitions()).thenAnswer((_) async => []);
    when(() => auth.currentUser).thenReturn(
      const AuthUser(id: 'user-1', displayName: 'Ada', isGuest: false),
    );
    when(() => auth.watchUser()).thenAnswer((_) => const Stream.empty());
    when(() => auth.signOut()).thenAnswer((_) async {});

    authBloc = AuthBloc(auth);
    competitionListCubit = CompetitionListCubit(competitions, authBloc);
    competitionCubit = CompetitionCubit(competitions, authBloc);
  });

  tearDown(() {
    competitionListCubit.close();
    competitionCubit.close();
    authBloc.close();
  });

  Widget wrap(GoRouter router) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: competitionListCubit),
      BlocProvider.value(value: authBloc),
      BlocProvider.value(value: competitionCubit),
    ],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );

  testWidgets(
    'landing here fresh (nothing to pop back to) offers a way to sign out',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const CompetitionsPage()),
        ],
      );

      await tester.pumpWidget(wrap(router));
      await tester.pumpAndSettle();

      final signOutButton = find.byIcon(Icons.logout);
      expect(signOutButton, findsOneWidget);

      await tester.tap(signOutButton);
      await tester.pumpAndSettle();

      verify(() => auth.signOut()).called(1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'reached by pushing from inside a competition (switching) relies on the '
    'back button instead',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/start',
        routes: [
          GoRoute(
            path: '/start',
            builder: (context, _) => Center(
              child: ElevatedButton(
                onPressed: () => context.push('/'),
                child: const Text('open'),
              ),
            ),
          ),
          GoRoute(path: '/', builder: (_, _) => const CompetitionsPage()),
        ],
      );

      await tester.pumpWidget(wrap(router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.logout), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
