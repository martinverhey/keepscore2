import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../../core/extensions/build_context_l10n.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/sheet.dart';
import '../../domain/match_entry.model.dart';

class MatchScoreSheet extends StatefulWidget {
  const MatchScoreSheet({super.key, required this.match});

  final MatchEntry match;

  @override
  State<MatchScoreSheet> createState() => _MatchScoreSheetState();
}

class _MatchScoreSheetState extends State<MatchScoreSheet> {
  late final _scoreA = TextEditingController(
    text: '${widget.match.teamAScore}',
  );
  late final _scoreB = TextEditingController(
    text: '${widget.match.teamBScore}',
  );

  @override
  void dispose() {
    _scoreA.dispose();
    _scoreB.dispose();
    super.dispose();
  }

  int? get _a => int.tryParse(_scoreA.text.trim());

  int? get _b => int.tryParse(_scoreB.text.trim());

  @override
  Widget build(BuildContext context) {
    final valid = _a != null && _b != null;

    return Sheet(
      title: context.l10n.matchEditScoreTitle,
      subtitle: context.l10n.matchEditScoreHelp,
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AdaptiveTextField(
              label: context.l10n.matchTeamA,
              controller: _scoreA,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 3,
              autofocus: true,
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AdaptiveTextField(
              label: context.l10n.matchTeamB,
              controller: _scoreB,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 3,
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      ),
      primaryButton: AdaptiveButton(
        label: context.l10n.commonSave,
        onPressed: valid ? () => Navigator.of(context).pop((_a!, _b!)) : null,
      ),
      secondaryButton: AdaptiveButton(
        label: context.l10n.commonCancel,
        kind: AdaptiveButtonKind.plain,
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }
}
