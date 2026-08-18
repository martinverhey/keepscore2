import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import 'competition_section.enum.dart';
import 'home_sidebar_competition.dart';

Future<CompetitionSection?> openHome(
  BuildContext context, {
  required bool replace,
  required String competitionId,
  required String? competitionName,
  required bool canManageSettings,
}) {
  final extra = HomeSidebarCompetition(
    competitionId: competitionId,
    competitionName: competitionName,
    canManageSettings: canManageSettings,
  );
  return replace
      ? GoRouter.of(
          context,
        ).pushReplacement<CompetitionSection>(Routes.home, extra: extra)
      : context.push<CompetitionSection>(Routes.home, extra: extra);
}
