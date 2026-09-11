import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/extensions/text_editing_controller.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/sheet.dart';
import '../../domain/bracket.model.dart';

Future<(int, int)?> showTournamentScoreSheet(
  BuildContext context, {
  required TournamentMatch match,
}) {
  return showAdaptiveSheet<(int, int)>(
    context,
    builder: (_) => TournamentScoreSheet(match: match),
  );
}

class TournamentScoreSheet extends StatefulWidget {
  const TournamentScoreSheet({super.key, required this.match});

  final TournamentMatch match;

  @override
  State<TournamentScoreSheet> createState() => _TournamentScoreSheetState();
}

class _TournamentScoreSheetState extends State<TournamentScoreSheet> {
  late final _scoreA = TextEditingController(
    text: widget.match.scoreA?.toString() ?? '',
  );
  late final _scoreB = TextEditingController(
    text: widget.match.scoreB?.toString() ?? '',
  );

  @override
  void dispose() {
    _scoreA.dispose();
    _scoreB.dispose();
    super.dispose();
  }

  int? get _a => _scoreA.intValue;
  int? get _b => _scoreB.intValue;

  bool get _canSave => _a != null && _b != null && _a != _b;

  @override
  Widget build(BuildContext context) {
    return Sheet(
      title: context.l10n.tournamentEnterScore,
      subtitle: _isDraw ? context.l10n.tournamentNoDraw : null,
      content: _scores(context),
      primaryButton: AdaptiveButton(
        label: context.l10n.tournamentSaveResult,
        onPressed: _canSave
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

  bool get _isDraw => _a != null && _a == _b;

  Widget _scores(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _field(_scoreA, _name(widget.match.playerA), true)),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: _field(_scoreB, _name(widget.match.playerB), false)),
      ],
    );
  }

  Widget _field(TextEditingController controller, String label, bool first) {
    return AdaptiveTextField(
      label: label,
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      maxLength: 3,
      autofocus: first,
      onChanged: (_) => setState(() {}),
    );
  }

  String _name(TournamentEntrant? entrant) => entrant?.displayName ?? '';
}
