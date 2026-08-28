import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import 'competition_section.enum.dart';
import 'home_sidebar_competition.dart';

Future<CompetitionSection?> openLanguage(
  BuildContext context, {
  required bool replace,
  HomeSidebarCompetition? sidebarCompetition,
}) {
  return replace
      ? GoRouter.of(context).pushReplacement<CompetitionSection>(
          Routes.language,
          extra: sidebarCompetition,
        )
      : context.push<CompetitionSection>(
          Routes.language,
          extra: sidebarCompetition,
        );
}
