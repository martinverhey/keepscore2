import 'package:flutter/widgets.dart';

import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../competition/domain/competition.model.dart';
import '../../domain/season.model.dart';
import '../pages/season_sheet.dart';

class SeasonFilterButton extends StatelessWidget {
  const SeasonFilterButton({
    super.key,
    required this.seasons,
    required this.selected,
    required this.seasonLength,
    required this.onSelected,
  });

  final List<Season> seasons;
  final Season selected;
  final SeasonLength seasonLength;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return AdaptiveBarAction(
      glyph: AdaptiveGlyph.filter,
      semanticLabel: context.l10n.leaderboardPickSeason,
      onPressed: () => _pick(context),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final seasonId = await showAdaptiveSheet<String>(
      context,
      builder: (_) => SeasonSheet(
        seasons: seasons,
        selected: selected,
        seasonLength: seasonLength,
      ),
    );
    if (seasonId != null) onSelected(seasonId);
  }
}
