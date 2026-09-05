import 'package:flutter/widgets.dart';

import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/extensions/string.extension.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/qr_scanner_view.dart';
import '../../../../core/widgets/sheet.dart';
import '../widgets/join_scan_result.dart';

Future<JoinScanResult?> showJoinScannerSheet(BuildContext context) {
  return showAdaptiveSheet<JoinScanResult>(
    context,
    builder: (_) => const JoinScannerSheet(),
  );
}

class JoinScannerSheet extends StatefulWidget {
  const JoinScannerSheet({super.key});

  @override
  State<JoinScannerSheet> createState() => _JoinScannerSheetState();
}

class _JoinScannerSheetState extends State<JoinScannerSheet> {
  bool _closing = false;

  @override
  Widget build(BuildContext context) {
    return Sheet(
      title: context.l10n.joinScanTitle,
      subtitle: context.l10n.joinScanSubtitle,
      content: QrScannerView(
        onCode: _scanned,
        unavailableMessage: context.l10n.joinScanUnavailable,
      ),
      primaryButton: AdaptiveButton(
        label: context.l10n.joinScanEnterCode,
        kind: AdaptiveButtonKind.tinted,
        onPressed: () => _close(const JoinScanResult.manualEntry()),
      ),
      secondaryButton: AdaptiveButton(
        label: context.l10n.commonCancel,
        kind: AdaptiveButtonKind.plain,
        onPressed: () => _close(null),
      ),
    );
  }

  void _scanned(String value) {
    if (!value.isJoinCode) return;
    _close(JoinScanResult.scanned(value.normalizedJoinCode));
  }

  void _close(JoinScanResult? result) {
    if (_closing) return;
    _closing = true;
    Navigator.of(context).pop(result);
  }
}
