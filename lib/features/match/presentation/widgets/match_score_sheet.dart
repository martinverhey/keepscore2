import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/extensions/text_editing_controller.extension.dart';
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

  int? get _a => _scoreA.intValue;
  int? get _b => _scoreB.intValue;

  @override
  Widget build(BuildContext context) {
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
        onPressed: _a != null && _b != null
            ? () => Navigator.of(context).pop((_a!, _b!))
            : null,
      ),
      secondaryButton: AdaptiveButton(
        label: context.l10n.commonCancel,
        kind: AdaptiveButtonKind.plain,
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }
}
