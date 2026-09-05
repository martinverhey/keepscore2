import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/widgets/adaptive/app_platform.dart';
import 'package:keepscore2/core/widgets/qr_scanner_view.dart';
import 'package:keepscore2/features/competition/presentation/widgets/join_scan_result.dart';
import 'package:keepscore2/features/competition/presentation/widgets/join_scanner_sheet.dart';
import 'package:keepscore2/l10n/app_localizations.dart';

Future<void> _pumpHarness(WidgetTester tester) async {
  AppPlatform.debugOverrideCupertino = false;

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const _OpenerStub(),
    ),
  );
  await tester.tap(find.byType(TextButton));
  await tester.pumpAndSettle();
}

void _scan(WidgetTester tester, String value) {
  tester.widget<QrScannerView>(find.byType(QrScannerView)).onCode(value);
}

void main() {
  tearDown(() => AppPlatform.debugOverrideCupertino = null);

  testWidgets('a scanned join code is normalized and handed back', (
    tester,
  ) async {
    await _pumpHarness(tester);

    _scan(tester, 'hdhs-39');
    await tester.pumpAndSettle();

    expect(find.byType(JoinScannerSheet), findsNothing);
    expect(find.text('scanned HDHS39'), findsOneWidget);
  });

  testWidgets('a QR code that is not a join code keeps the scanner open', (
    tester,
  ) async {
    await _pumpHarness(tester);

    _scan(tester, 'https://example.com/not-a-join-code');
    await tester.pumpAndSettle();

    expect(find.byType(JoinScannerSheet), findsOneWidget);
  });

  testWidgets('entering the code manually hands back no code', (tester) async {
    await _pumpHarness(tester);

    final l10n = AppLocalizations.of(
      tester.element(find.byType(JoinScannerSheet)),
    );
    await tester.tap(find.text(l10n.joinScanEnterCode));
    await tester.pumpAndSettle();

    expect(find.byType(JoinScannerSheet), findsNothing);
    expect(find.text('scanned null'), findsOneWidget);
  });

  testWidgets('cancelling hands nothing back', (tester) async {
    await _pumpHarness(tester);

    final l10n = AppLocalizations.of(
      tester.element(find.byType(JoinScannerSheet)),
    );
    await tester.tap(find.text(l10n.commonCancel));
    await tester.pumpAndSettle();

    expect(find.byType(JoinScannerSheet), findsNothing);
    expect(find.textContaining('scanned'), findsNothing);
  });

  testWidgets('the sheet leads with the camera', (tester) async {
    await _pumpHarness(tester);

    final l10n = AppLocalizations.of(
      tester.element(find.byType(JoinScannerSheet)),
    );
    expect(find.byType(QrScannerView), findsOneWidget);
    expect(find.text(l10n.joinScanTitle), findsOneWidget);
  });
}

class _OpenerStub extends StatefulWidget {
  const _OpenerStub();

  @override
  State<_OpenerStub> createState() => _OpenerStubState();
}

class _OpenerStubState extends State<_OpenerStub> {
  JoinScanResult? _result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _result == null
            ? TextButton(onPressed: _open, child: const Text('open'))
            : Text('scanned ${_result!.code}'),
      ),
    );
  }

  Future<void> _open() async {
    final result = await showJoinScannerSheet(context);
    if (result == null) return;
    setState(() => _result = result);
  }
}
