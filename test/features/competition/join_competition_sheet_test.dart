import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/app/dependency_injection/injector.dart';
import 'package:keepscore2/core/error/failure.dart';
import 'package:keepscore2/core/widgets/adaptive/app_platform.dart';
import 'package:keepscore2/features/competition/domain/competition_repository.dart';
import 'package:keepscore2/features/competition/domain/join_preview.model.dart';
import 'package:keepscore2/features/competition/presentation/cubit/join_competition_cubit.dart';
import 'package:keepscore2/features/competition/presentation/widgets/join_competition_sheet.dart';
import 'package:keepscore2/features/competition/presentation/widgets/join_result.dart';
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

Future<MockCompetitionRepository> _pumpHarness(
  WidgetTester tester, {
  String? code,
  MockCompetitionRepository? competitions,
}) async {
  AppPlatform.debugOverrideCupertino = false;

  final repository = competitions ?? MockCompetitionRepository();
  if (competitions == null) {
    when(() => repository.preview(any())).thenAnswer((_) async => _preview());
  }
  getIt.registerFactory<JoinCompetitionCubit>(
    () => JoinCompetitionCubit(repository),
  );

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: _OpenerStub(code: code),
    ),
  );
  await tester.tap(find.byType(TextButton));
  await tester.pumpAndSettle();

  return repository;
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
    await _pumpHarness(tester);

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
    expect(find.widgetWithText(TextField, _joinCode), findsOneWidget);
  });

  testWidgets('claiming a player joins and hands the competition id back', (
    tester,
  ) async {
    final competitions = await _pumpHarness(tester);
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
    expect(find.text('joined c1'), findsOneWidget);
  });

  testWidgets('a scanned code opens straight on the confirm step', (
    tester,
  ) async {
    final competitions = await _pumpHarness(tester, code: _joinCode);

    verify(() => competitions.preview(_joinCode)).called(1);
    expect(find.text('Office Table Tennis'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('going back from a scanned code closes the sheet', (
    tester,
  ) async {
    await _pumpHarness(tester, code: _joinCode);

    final l10n = AppLocalizations.of(
      tester.element(find.byType(JoinCompetitionSheet)),
    );
    await tester.tap(find.text(l10n.commonBack));
    await tester.pumpAndSettle();

    expect(find.byType(JoinCompetitionSheet), findsNothing);
    expect(find.text('back'), findsOneWidget);
  });

  testWidgets('a scanned code that cannot be looked up shows the failure', (
    tester,
  ) async {
    final competitions = MockCompetitionRepository();
    when(
      () => competitions.preview(any()),
    ).thenThrow(const ValidationFailure('No competition with that code.'));
    await _pumpHarness(tester, code: _joinCode, competitions: competitions);

    expect(find.text('No competition with that code.'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('cancelling hands nothing back', (tester) async {
    await _pumpHarness(tester);

    final l10n = AppLocalizations.of(
      tester.element(find.byType(JoinCompetitionSheet)),
    );
    await tester.tap(find.text(l10n.commonCancel));
    await tester.pumpAndSettle();

    expect(find.byType(JoinCompetitionSheet), findsNothing);
    expect(find.text('dismissed'), findsOneWidget);
  });
}

class _OpenerStub extends StatefulWidget {
  const _OpenerStub({this.code});

  final String? code;

  @override
  State<_OpenerStub> createState() => _OpenerStubState();
}

class _OpenerStubState extends State<_OpenerStub> {
  JoinResult? _result;
  bool _closed = false;

  String get _label => switch (_result) {
    null => 'dismissed',
    JoinResult(competitionId: final competitionId?) => 'joined $competitionId',
    _ => 'back',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _closed
            ? Text(_label)
            : TextButton(onPressed: _open, child: const Text('open')),
      ),
    );
  }

  Future<void> _open() async {
    final result = await showJoinCompetitionSheet(context, code: widget.code);
    setState(() {
      _result = result;
      _closed = true;
    });
  }
}
