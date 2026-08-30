import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../match/presentation/widgets/new_match_sheet.dart';
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
      ],
      selectedIndex: current == CompetitionTab.leaderboard ? 0 : 1,
      onTap: (index) => _select(context, index),
      action: isRegistered ? _newMatch(context) : null,
    );
  }

  AdaptiveTabBarAction _newMatch(BuildContext context) {
    return AdaptiveTabBarAction(
      glyph: AdaptiveGlyph.newMatch,
      label: context.l10n.matchNew,
      onPressed: () =>
          showNewMatchSheet(context, competitionId: competitionId),
    );
  }

  void _select(BuildContext context, int index) {
    final tab = index == 0
        ? CompetitionTab.leaderboard
        : CompetitionTab.matches;
    if (tab == current) return;
    context.go(
      tab == CompetitionTab.leaderboard
          ? Routes.leaderboard(competitionId)
          : Routes.matches(competitionId),
    );
  }
}
