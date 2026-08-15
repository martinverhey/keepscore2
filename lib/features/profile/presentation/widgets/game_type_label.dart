import 'package:flutter/widgets.dart';

import '../../../../core/extensions/build_context_l10n.dart';
import '../../../match/domain/game_type.enum.dart';

String gameTypeLabel(BuildContext context, GameType gameType) =>
    switch (gameType) {
      GameType.oneVOne => context.l10n.gameType1v1,
      GameType.twoVTwo => context.l10n.gameType2v2,
      GameType.threeVThree => context.l10n.gameType3v3,
      GameType.fourVFour => context.l10n.gameType4v4,
      GameType.mixed => context.l10n.gameTypeMixed,
    };
