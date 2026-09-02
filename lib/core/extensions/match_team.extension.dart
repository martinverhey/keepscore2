import 'package:flutter/widgets.dart';

import '../../features/match/domain/match_entry.model.dart';
import 'build_context.extension.dart';

extension MatchTeamLabel on MatchTeam {
  String label(BuildContext context, {required bool isOneVsOne}) =>
      switch (this) {
        MatchTeam.a => isOneVsOne
            ? context.l10n.matchPlayerA
            : context.l10n.matchTeamA,
        MatchTeam.b => isOneVsOne
            ? context.l10n.matchPlayerB
            : context.l10n.matchTeamB,
      };
}
