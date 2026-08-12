import 'package:flutter/widgets.dart';

import '../../../../core/extensions/build_context_l10n.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/sheet.dart';
import '../../../competition/domain/competition.dart';
import '../../domain/season.dart';
import 'season_label.dart';

class SeasonSheet extends StatelessWidget {
  const SeasonSheet({
    super.key,
    required this.seasons,
    required this.selected,
    required this.seasonLength,
  });

  final List<Season> seasons;
  final Season? selected;
  final SeasonLength seasonLength;

  @override
  Widget build(BuildContext context) {
    return Sheet(
      title: context.l10n.leaderboardPickSeason,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final season in seasons)
            AdaptiveButton(
              label: seasonLabel(context, season, seasonLength),
              kind: season == selected
                  ? AdaptiveButtonKind.tinted
                  : AdaptiveButtonKind.plain,
              onPressed: () => Navigator.of(context).pop(season.id),
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
}
