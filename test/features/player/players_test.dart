import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/app/app.dart';
import 'package:keepscore2/features/player/domain/player.model.dart';
import 'package:keepscore2/features/player/domain/player_repository.dart';
import 'package:keepscore2/features/player/presentation/cubit/players_cubit.dart';
import 'package:keepscore2/features/player/presentation/widgets/player_row.dart';
import 'package:keepscore2/features/player/presentation/widgets/players.dart';
import 'package:keepscore2/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
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
    when(() => repository.watch(any())).thenAnswer((_) => const Stream.empty());
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
        localizationsDelegates: KeepScoreApp.localizationsDelegates,
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

  Future<List<String>> rowActions(WidgetTester tester, String name) async {
    final row = find.ancestor(
      of: find.text(name),
      matching: find.byType(PlayerRow),
    );
    final more = find.descendant(
      of: row,
      matching: find.byTooltip('More actions'),
    );
    if (more.evaluate().isEmpty) return const [];

    await tester.tap(more);
    await tester.pumpAndSettle();
    final labels = [
      for (final label in const [
        'Rename',
        'Add back',
        'Remove from player list',
      ])
        if (find.text(label).evaluate().isNotEmpty) label,
    ];
    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();
    return labels;
  }

  testWidgets('the owner may rename a placeholder', (tester) async {
    await pumpPlayers(tester, myUserId: 'owner-1');

    expect(await rowActions(tester, 'Tester1'), [
      'Rename',
      'Remove from player list',
    ]);
  });

  testWidgets('the owner may rename their own player', (tester) async {
    await pumpPlayers(tester, myUserId: 'owner-1');

    expect(await rowActions(tester, 'Henkie'), ['Rename']);
  });

  testWidgets('the owner may remove but not rename a claimed player', (
    tester,
  ) async {
    await pumpPlayers(tester, myUserId: 'owner-1');

    expect(await rowActions(tester, 'Tester10'), ['Remove from player list']);
  });

  testWidgets('a member reaches their own player and nobody else', (
    tester,
  ) async {
    await pumpPlayers(tester, myUserId: 'guest-2');

    expect(await rowActions(tester, 'Tester10'), ['Rename']);
    expect(find.byTooltip('More actions'), findsOneWidget);
  });

  testWidgets('marks the viewer\'s own row with the selected fill', (
    tester,
  ) async {
    await pumpPlayers(tester, myUserId: 'guest-2');

    Color? fillOf(String name) {
      final container = tester.widget<Container>(
        find
            .ancestor(of: find.text(name), matching: find.byType(Container))
            .first,
      );
      return (container.decoration! as BoxDecoration).color;
    }

    expect(fillOf('Tester10'), isNot(fillOf('Tester1')));
  });
}
