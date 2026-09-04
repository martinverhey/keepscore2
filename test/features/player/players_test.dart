import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/features/player/domain/player.model.dart';
import 'package:keepscore2/features/player/domain/player_repository.dart';
import 'package:keepscore2/features/player/presentation/cubit/players_cubit.dart';
import 'package:keepscore2/features/player/presentation/widgets/player_row.dart';
import 'package:keepscore2/features/player/presentation/widgets/players.dart';
import 'package:keepscore2/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockPlayerRepository extends Mock implements PlayerRepository {}

const _placeholder = Player(
  id: 'p1',
  competitionId: 'c1',
  displayName: 'Tester1',
  isActive: true,
);

const _owner = Player(
  id: 'p2',
  competitionId: 'c1',
  displayName: 'Henkie',
  isActive: true,
  userId: 'owner-1',
);

const _claimed = Player(
  id: 'p3',
  competitionId: 'c1',
  displayName: 'Tester10',
  isActive: true,
  userId: 'guest-2',
);

void main() {
  late MockPlayerRepository repository;

  setUp(() {
    repository = MockPlayerRepository();
    when(
      () => repository.watch(any()),
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => repository.currentPlayers('c1'),
    ).thenAnswer((_) async => const [_placeholder, _owner, _claimed]);
  });

  Future<void> pumpPlayers(
    WidgetTester tester, {
    required String myUserId,
  }) async {
    final cubit = PlayersCubit(repository, 'c1')..load();
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider.value(
            value: cubit,
            child: SingleChildScrollView(
              child: Players(
                ownerUserId: 'owner-1',
                myUserId: myUserId,
                isRegistered: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openActions(WidgetTester tester, String displayName) async {
    final row = find.ancestor(
      of: find.text(displayName),
      matching: find.byType(PlayerRow),
    );
    await tester.tap(find.descendant(of: row, matching: find.text('Edit')));
    await tester.pumpAndSettle();
  }

  testWidgets('the owner may rename a placeholder', (tester) async {
    await pumpPlayers(tester, myUserId: 'owner-1');
    await openActions(tester, 'Tester1');

    expect(find.text('Rename'), findsOneWidget);
    expect(find.text('Remove from player list'), findsOneWidget);
  });

  testWidgets('the owner may rename their own player', (tester) async {
    await pumpPlayers(tester, myUserId: 'owner-1');
    await openActions(tester, 'Henkie');

    expect(find.text('Rename'), findsOneWidget);
    expect(find.text('Remove from player list'), findsNothing);
  });

  testWidgets('the owner may remove but not rename a claimed player', (
    tester,
  ) async {
    await pumpPlayers(tester, myUserId: 'owner-1');
    await openActions(tester, 'Tester10');

    expect(find.text('Rename'), findsNothing);
    expect(find.text('Remove from player list'), findsOneWidget);
  });

  testWidgets('a member reaches their own player and nobody else', (
    tester,
  ) async {
    await pumpPlayers(tester, myUserId: 'guest-2');

    expect(find.text('Edit'), findsOneWidget);

    await openActions(tester, 'Tester10');
    expect(find.text('Rename'), findsOneWidget);
    expect(find.text('Remove from player list'), findsNothing);
  });
}
