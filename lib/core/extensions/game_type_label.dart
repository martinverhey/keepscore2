import 'package:flutter/widgets.dart';

import '../../features/match/domain/game_type.enum.dart';
import 'build_context_l10n.dart';

extension GameTypeLabel on GameType {
  String label(BuildContext context) => switch (this) {
    GameType.oneVOne => context.l10n.gameType1v1,
    GameType.twoVTwo => context.l10n.gameType2v2,
    GameType.threeVThree => context.l10n.gameType3v3,
    GameType.fourVFour => context.l10n.gameType4v4,
    GameType.mixed => context.l10n.gameTypeMixed,
  };
}
