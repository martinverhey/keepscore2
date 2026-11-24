import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/app/app.dart';
import 'package:keepscore2/core/widgets/adaptive/adaptive.dart';
import 'package:keepscore2/features/auth/domain/auth_repository.dart';
import 'package:keepscore2/features/auth/domain/auth_user.model.dart';
import 'package:keepscore2/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:keepscore2/features/competition/domain/competition.model.dart';
import 'package:keepscore2/features/competition/domain/competition_repository.dart';
import 'package:keepscore2/features/competition/presentation/cubit/competition_cubit.dart';
import 'package:keepscore2/features/player/domain/player.model.dart';
import 'package:keepscore2/features/player/domain/player_repository.dart';
import 'package:keepscore2/features/player/presentation/cubit/players_cubit.dart';
import 'package:keepscore2/features/player/presentation/pages/manage_players_sheet.dart';
import 'package:keepscore2/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockCompetitionRepository extends Mock implements CompetitionRepository {}

class MockPlayerRepository extends Mock implements PlayerRepository {}

const _ownerId = 'owner-1';

final _overview = CompetitionOverview(
  competition: Competition(
    id: 'c1',
    joinCode: 'HDHS39',
    name: 'Office Table Tennis',
    ownerId: _ownerId,
    seasonLength: SeasonLength.monthly,
    timezone: 'Europe/Amsterdam',
    startingRating: 1000,
    kFactor: 32,
    movEnabled: true,
    movCap: 2.5,
    createdAt: DateTime.utc(2026, 8, 1),
  ),
  playerCount: 1,
  matchCount: 0,
  myPlayerId: 'p1',
);

const _player = Player(
  id: 'p1',
  competitionId: 'c1',
  displayName: 'Henkie',
  isActive: true,
  userId: _ownerId,
);

void main() {
  Future<void> pumpSheet(WidgetTester tester, {required String userId}) async {
    final auth = MockAuthRepository();
    when(
      () => auth.currentUser,
    ).thenReturn(AuthUser(id: userId, displayName: 'Ada', isGuest: false));
    when(() => auth.watchUser()).thenAnswer((_) => const Stream.empty());

    final competitions = MockCompetitionRepository();
    when(() => competitions.overview('c1')).thenAnswer((_) async => _overview);

    final players = MockPlayerRepository();
    when(() => players.watch(any())).thenAnswer((_) => const Stream.empty());
    when(
      () => players.currentPlayers('c1'),
    ).thenAnswer((_) async => const [_player]);

    final authCubit = AuthCubit(auth);
    final competitionCubit = CompetitionCubit(competitions, authCubit);
    final playersCubit = PlayersCubit(players, 'c1')..load();
    addTearDown(() async {
      await playersCubit.close();
      await competitionCubit.close();
      await authCubit.close();
    });
    await competitionCubit.select('c1');

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: authCubit),
          BlocProvider<CompetitionCubit>.value(value: competitionCubit),
          BlocProvider<PlayersCubit>.value(value: playersCubit),
        ],
        child: const MaterialApp(
          localizationsDelegates: KeepScoreApp.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: ManagePlayersSheet()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder addAction() => find.byWidgetPredicate(
    (widget) =>
        widget is AdaptiveBarAction && widget.glyph == AdaptiveGlyph.add,
  );

  testWidgets('the owner adds a player from a + centred on the title', (
    tester,
  ) async {
    await pumpSheet(tester, userId: _ownerId);

    final l10n = AppLocalizations.of(
      tester.element(find.byType(ManagePlayersSheet)),
    );
    expect(addAction(), findsOneWidget);
    expect(
      tester.getCenter(addAction()).dy,
      moreOrLessEquals(
        tester.getCenter(find.text(l10n.playersManageTitle)).dy,
        epsilon: 0.5,
      ),
    );

    await tester.tap(addAction());
    await tester.pumpAndSettle();

    expect(find.text(l10n.playersAddSubtitle), findsOneWidget);
  });

  testWidgets('anyone else gets no add action', (tester) async {
    await pumpSheet(tester, userId: 'someone-else');

    expect(addAction(), findsNothing);
  });
}
