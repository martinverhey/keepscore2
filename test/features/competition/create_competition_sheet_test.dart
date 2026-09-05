import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/app/dependency_injection/injector.dart';
import 'package:keepscore2/core/widgets/adaptive/adaptive.dart';
import 'package:keepscore2/features/competition/domain/competition.model.dart';
import 'package:keepscore2/features/competition/domain/competition_repository.dart';
import 'package:keepscore2/features/competition/presentation/cubit/create_competition_cubit.dart';
import 'package:keepscore2/features/competition/presentation/pages/create_competition_sheet.dart';
import 'package:keepscore2/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockCompetitionRepository extends Mock implements CompetitionRepository {}

final _created = Competition(
  id: 'comp-1',
  joinCode: 'HDHS39',
  name: 'Office Table Tennis',
  ownerId: 'user-1',
  seasonLength: SeasonLength.quarterly,
  timezone: 'Europe/Amsterdam',
  startingRating: 1000,
  kFactor: 32,
  movEnabled: true,
  movCap: 2.5,
  allowDraws: true,
  createdAt: DateTime.utc(2026, 8, 9),
);

Future<void> _openSheet(
  WidgetTester tester,
  MockCompetitionRepository repository, {
  void Function(String?)? onClosed,
}) async {
  AppPlatform.debugOverrideCupertino = false;

  getIt.registerFactory<CreateCompetitionCubit>(
    () => CreateCompetitionCubit(repository),
  );
  addTearDown(() => getIt.reset(dispose: false));

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () async {
                final competitionId = await showCreateCompetitionSheet(context);
                onClosed?.call(competitionId);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  expect(find.byType(CreateCompetitionSheet), findsOneWidget);
}

void main() {
  late MockCompetitionRepository repository;

  setUp(() {
    repository = MockCompetitionRepository();
    registerFallbackValue(SeasonLength.monthly);
    when(
      () => repository.create(
        name: any(named: 'name'),
        seasonLength: any(named: 'seasonLength'),
        displayName: any(named: 'displayName'),
      ),
    ).thenAnswer((_) async => _created);
  });

  tearDown(() => AppPlatform.debugOverrideCupertino = null);

  testWidgets('creating from the sheet closes it with the new competition id', (
    tester,
  ) async {
    String? closedWith;
    await _openSheet(
      tester,
      repository,
      onClosed: (competitionId) => closedWith = competitionId,
    );

    final l10n = AppLocalizations.of(
      tester.element(find.byType(CreateCompetitionSheet)),
    );

    await tester.enterText(find.byType(TextField), 'Office Table Tennis');
    await tester.pump();
    await tester.tap(find.text(l10n.seasonQuarterly));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.competitionsCreateShort));
    await tester.pumpAndSettle();

    verify(
      () => repository.create(
        name: 'Office Table Tennis',
        seasonLength: SeasonLength.quarterly,
      ),
    ).called(1);
    expect(find.byType(CreateCompetitionSheet), findsNothing);
    expect(closedWith, 'comp-1');
  });

  testWidgets('a name shorter than two characters cannot be submitted', (
    tester,
  ) async {
    await _openSheet(tester, repository);

    final l10n = AppLocalizations.of(
      tester.element(find.byType(CreateCompetitionSheet)),
    );

    await tester.enterText(find.byType(TextField), 'A');
    await tester.pumpAndSettle();

    expect(find.text(l10n.competitionNameTooShort), findsOneWidget);

    await tester.tap(find.text(l10n.competitionsCreateShort));
    await tester.pumpAndSettle();

    verifyNever(
      () => repository.create(
        name: any(named: 'name'),
        seasonLength: any(named: 'seasonLength'),
      ),
    );
    expect(find.byType(CreateCompetitionSheet), findsOneWidget);
  });

  testWidgets('cancelling closes the sheet without creating anything', (
    tester,
  ) async {
    String? closedWith = 'unset';
    await _openSheet(
      tester,
      repository,
      onClosed: (competitionId) => closedWith = competitionId,
    );

    final l10n = AppLocalizations.of(
      tester.element(find.byType(CreateCompetitionSheet)),
    );

    await tester.tap(find.text(l10n.commonCancel));
    await tester.pumpAndSettle();

    expect(find.byType(CreateCompetitionSheet), findsNothing);
    expect(closedWith, isNull);
    verifyNever(
      () => repository.create(
        name: any(named: 'name'),
        seasonLength: any(named: 'seasonLength'),
      ),
    );
  });
}
