import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/app/dependency_injection/injector.dart';
import 'package:keepscore2/core/widgets/adaptive/app_platform.dart';
import 'package:keepscore2/features/competition/domain/competition_repository.dart';
import 'package:keepscore2/features/competition/domain/join_preview.model.dart';
import 'package:keepscore2/features/competition/presentation/cubit/join_competition_cubit.dart';
import 'package:keepscore2/features/competition/presentation/widgets/join_competition_sheet.dart';
import 'package:keepscore2/features/player/domain/player.model.dart';
import 'package:keepscore2/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockCompetitionRepository extends Mock implements CompetitionRepository {}

const _joinCode = 'HDHS39';

JoinPreview _preview({bool alreadyMember = false}) => JoinPreview(
  competitionId: 'c1',
  name: 'Office Table Tennis',
  ownerName: 'Ada',
  playerCount: 5,
  alreadyMember: alreadyMember,
  claimable: const [ClaimablePlayer(id: 'p-chris', displayName: 'Chris')],
);

Future<MockCompetitionRepository> _pumpHarness(WidgetTester tester) async {
  AppPlatform.debugOverrideCupertino = false;

  final competitions = MockCompetitionRepository();
  getIt.registerFactory<JoinCompetitionCubit>(
    () => JoinCompetitionCubit(competitions),
  );

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const _OpenerStub(),
    ),
  );
  await tester.tap(find.byType(TextButton));
  await tester.pumpAndSettle();

  return competitions;
}

Future<void> _lookUpCode(WidgetTester tester, AppLocalizations l10n) async {
  await tester.enterText(find.byType(TextField), _joinCode);
  await tester.pump();
  await tester.tap(find.text(l10n.joinLookUp));
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() async {
    AppPlatform.debugOverrideCupertino = null;
    await getIt.reset(dispose: false);
  });

  testWidgets('a looked-up code moves the sheet on to its confirm step', (
    tester,
  ) async {
    final competitions = await _pumpHarness(tester);
    when(() => competitions.preview(any())).thenAnswer((_) async => _preview());

    final l10n = AppLocalizations.of(
      tester.element(find.byType(JoinCompetitionSheet)),
    );
    await _lookUpCode(tester, l10n);

    expect(find.text('Office Table Tennis'), findsOneWidget);
    expect(find.text('Chris'), findsOneWidget);

    await tester.tap(find.text(l10n.commonBack));
    await tester.pumpAndSettle();

    expect(find.text(l10n.joinTitle), findsOneWidget);
    expect(find.byType(JoinCompetitionSheet), findsOneWidget);
  });

  testWidgets('claiming a player joins and hands the competition id back', (
    tester,
  ) async {
    final competitions = await _pumpHarness(tester);
    when(() => competitions.preview(any())).thenAnswer((_) async => _preview());
    when(
      () => competitions.join(
        joinCode: any(named: 'joinCode'),
        claimPlayerId: any(named: 'claimPlayerId'),
        displayName: any(named: 'displayName'),
      ),
    ).thenAnswer(
      (_) async => const Player(
        id: 'p-chris',
        competitionId: 'c1',
        displayName: 'Chris',
        isActive: true,
      ),
    );

    final l10n = AppLocalizations.of(
      tester.element(find.byType(JoinCompetitionSheet)),
    );
    await _lookUpCode(tester, l10n);

    await tester.tap(find.text('Chris'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.joinConfirm));
    await tester.pumpAndSettle();

    verify(
      () => competitions.join(
        joinCode: _joinCode,
        claimPlayerId: 'p-chris',
        displayName: null,
      ),
    ).called(1);
    expect(find.byType(JoinCompetitionSheet), findsNothing);
    expect(find.text('opened c1'), findsOneWidget);
  });

  testWidgets('cancelling hands nothing back', (tester) async {
    final competitions = await _pumpHarness(tester);
    when(() => competitions.preview(any())).thenAnswer((_) async => _preview());

    final l10n = AppLocalizations.of(
      tester.element(find.byType(JoinCompetitionSheet)),
    );
    await tester.tap(find.text(l10n.commonCancel));
    await tester.pumpAndSettle();

    expect(find.byType(JoinCompetitionSheet), findsNothing);
    expect(find.text('opened c1'), findsNothing);
  });
}

class _OpenerStub extends StatefulWidget {
  const _OpenerStub();

  @override
  State<_OpenerStub> createState() => _OpenerStubState();
}

class _OpenerStubState extends State<_OpenerStub> {
  String? _opened;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _opened == null
            ? TextButton(onPressed: _open, child: const Text('open'))
            : Text('opened $_opened'),
      ),
    );
  }

  Future<void> _open() async {
    final competitionId = await showJoinCompetitionSheet(context);
    if (competitionId == null) return;
    setState(() => _opened = competitionId);
  }
}
