import 'package:flutter/widgets.dart';

import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/extensions/season.extension.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/sheet.dart';
import '../../../competition/domain/competition.model.dart';
import '../../domain/season.model.dart';

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
              label: season.label(context, seasonLength),
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
