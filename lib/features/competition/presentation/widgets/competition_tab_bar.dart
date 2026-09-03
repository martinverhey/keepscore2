import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import 'competition_tab.enum.dart';

class CompetitionTabBar extends StatelessWidget {
  const CompetitionTabBar({
    super.key,
    required this.competitionId,
    required this.current,
    required this.isRegistered,
  });

  final String competitionId;
  final CompetitionTab current;
  final bool isRegistered;

  @override
  Widget build(BuildContext context) {
    return AdaptiveBottomTabBar(
      items: [
        AdaptiveTabBarItem(
          glyph: AdaptiveGlyph.leaderboard,
          label: context.l10n.leaderboardTitle,
        ),
        AdaptiveTabBarItem(
          glyph: AdaptiveGlyph.matches,
          label: context.l10n.matchesTitle,
        ),
        AdaptiveTabBarItem(
          glyph: AdaptiveGlyph.competitions,
          label: context.l10n.competitionsTitle,
        ),
      ],
      selectedIndex: current.index,
      onTap: (index) => _select(context, CompetitionTab.values[index]),
      reservesTrailingAction: isRegistered,
    );
  }

  void _select(BuildContext context, CompetitionTab tab) {
    if (tab == current) return;
    context.go(switch (tab) {
      CompetitionTab.leaderboard => Routes.leaderboard(competitionId),
      CompetitionTab.matches => Routes.matches(competitionId),
      CompetitionTab.competitions => Routes.competitions(competitionId),
    });
  }
}
