import 'package:flutter/widgets.dart';

import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/pill_dropdown.dart';
import '../../../competition/domain/competition.model.dart';
import '../../domain/season.model.dart';
import 'season_label.dart';
import 'season_sheet.dart';

class SeasonDropdown extends StatelessWidget {
  const SeasonDropdown({
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
    return PillDropdown(
      label: seasonLabel(context, selected, seasonLength),
      onTap: () => _pick(context),
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
