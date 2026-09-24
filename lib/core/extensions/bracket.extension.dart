import 'package:flutter/widgets.dart';

import '../../features/tournament/domain/bracket.model.dart';
import 'build_context.extension.dart';

extension BracketRoundLabel on Bracket {
  String roundLabel(BuildContext context, int round) =>
      switch (roundCount - round) {
        0 => context.l10n.tournamentFinalRound,
        1 => context.l10n.tournamentSemiFinalRound,
        2 => context.l10n.tournamentQuarterFinalRound,
        _ => context.l10n.tournamentRound(round),
      };
}
