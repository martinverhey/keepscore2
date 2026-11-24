import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/app/app.dart';
import 'package:keepscore2/app/dependency_injection/injector.dart';
import 'package:keepscore2/core/error/failure.dart';
import 'package:keepscore2/core/error/failure_messages.dart';
import 'package:keepscore2/core/widgets/adaptive/adaptive.dart';
import 'package:keepscore2/features/auth/domain/auth_repository.dart';
import 'package:keepscore2/features/auth/domain/auth_user.model.dart';
import 'package:keepscore2/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:keepscore2/features/competition/domain/competition.model.dart';
import 'package:keepscore2/features/competition/domain/competition_repository.dart';
import 'package:keepscore2/features/settings/presentation/cubit/competition_edit_cubit.dart';
import 'package:keepscore2/features/settings/presentation/pages/competition_edit_sheet.dart';
import 'package:keepscore2/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockCompetitionRepository extends Mock implements CompetitionRepository {}

final _competition = Competition(
  id: 'c1',
  joinCode: 'HDHS39',
  name: 'Office Table Tennis',
  ownerId: 'u1',
  seasonLength: SeasonLength.quarterly,
  timezone: 'Europe/Amsterdam',
  startingRating: 1000,
  kFactor: 60,
  movEnabled: true,
  movCap: 10,
  shutoutBonus: true,
  createdAt: DateTime.utc(2026, 8, 9),
);

Future<List<bool>> _openSheet(
  WidgetTester tester,
  MockCompetitionRepository repository,
) async {
  AppPlatform.debugOverrideCupertino = false;

  final auth = MockAuthRepository();
  when(
    () => auth.currentUser,
  ).thenReturn(const AuthUser(id: 'u1', displayName: 'Ada', isGuest: false));
  when(() => auth.watchUser()).thenAnswer((_) => const Stream.empty());
  final authCubit = AuthCubit(auth);
  addTearDown(authCubit.close);

  getIt.registerFactoryParam<CompetitionEditCubit, String, void>(
    (competitionId, _) => CompetitionEditCubit(repository, competitionId),
  );
  addTearDown(() => getIt.reset(dispose: false));

  when(() => repository.overview('c1')).thenAnswer(
    (_) async => CompetitionOverview(
      competition: _competition,
      playerCount: 5,
      matchCount: 11,
    ),
  );

  final results = <bool>[];
  await tester.pumpWidget(
    BlocProvider.value(
      value: authCubit,
      child: MaterialApp(
        localizationsDelegates: KeepScoreApp.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async => results.add(
                  await showCompetitionEditSheet(context, competitionId: 'c1'),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  expect(find.byType(CompetitionEditSheet), findsOneWidget);
  return results;
}

When<Future<Competition>> _stubSave(MockCompetitionRepository repository) =>
    when(
      () => repository.updateSettings(
        competitionId: any(named: 'competitionId'),
        name: any(named: 'name'),
        seasonLength: any(named: 'seasonLength'),
        kFactor: any(named: 'kFactor'),
        movEnabled: any(named: 'movEnabled'),
        movCap: any(named: 'movCap'),
        shutoutBonus: any(named: 'shutoutBonus'),
        shutoutMultiplier: any(named: 'shutoutMultiplier'),
      ),
    );

void main() {
  late MockCompetitionRepository repository;

  setUpAll(() => registerFallbackValue(SeasonLength.monthly));

  setUp(() => repository = MockCompetitionRepository());

  tearDown(() => AppPlatform.debugOverrideCupertino = null);

  testWidgets('a successful save closes the sheet', (tester) async {
    _stubSave(repository).thenAnswer((_) async => _competition);
    final results = await _openSheet(tester, repository);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(CompetitionEditSheet)),
    );

    await tester.tap(find.text(l10n.competitionEditSave));
    await tester.pumpAndSettle();

    expect(find.byType(CompetitionEditSheet), findsNothing);
    expect(results, [true]);
  });

  testWidgets('a rejected save keeps the sheet open and shows why', (
    tester,
  ) async {
    _stubSave(repository).thenThrow(const PermissionFailure());
    final results = await _openSheet(tester, repository);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(CompetitionEditSheet)),
    );

    await tester.tap(find.text(l10n.competitionEditSave));
    await tester.pumpAndSettle();

    expect(find.byType(CompetitionEditSheet), findsOneWidget);
    expect(
      find.text(const PermissionFailure().localized(l10n)),
      findsOneWidget,
    );
    expect(results, isEmpty);
  });
}
