import 'package:flutter/widgets.dart';

import '../../../../core/extensions/build_context_l10n.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/sheet.dart';
import '../../../competition/domain/competition.dart';
import '../../domain/season.dart';
import '../cubit/leaderboard_cubit.dart';
import 'season_label.dart';

class SeasonSheet extends StatelessWidget {
  const SeasonSheet({
    super.key,
    required this.state,
    required this.seasonLength,
  });

  final LeaderboardState state;
  final SeasonLength seasonLength;

  @override
  Widget build(BuildContext context) {
    return Sheet(
      title: context.l10n.leaderboardPickSeason,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final season in state.seasons)
            AdaptiveButton(
              label: _label(context, season),
              kind: season == state.selectedSeason
                  ? AdaptiveButtonKind.tinted
                  : AdaptiveButtonKind.plain,
              onPressed: () => Navigator.of(context).pop(season.startsAt),
            ),
        ],
      ),
      secondaryButton: AdaptiveButton(
        label: context.l10n.commonCancel,
        kind: AdaptiveButtonKind.plain,
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  String _label(BuildContext context, Season season) {
    final label = seasonLabel(context, season, seasonLength);
    return season == state.currentSeason
        ? '$label · ${context.l10n.leaderboardCurrentSeason}'
        : label;
  }
}
