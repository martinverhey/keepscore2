import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import 'competition_section.enum.dart';
import 'home_sidebar_competition.dart';

Future<CompetitionSection?> openTheme(
  BuildContext context, {
  required bool replace,
  HomeSidebarCompetition? sidebarCompetition,
}) {
  return replace
      ? GoRouter.of(context).pushReplacement<CompetitionSection>(
          Routes.theme,
          extra: sidebarCompetition,
        )
      : context.push<CompetitionSection>(
          Routes.theme,
          extra: sidebarCompetition,
        );
}
