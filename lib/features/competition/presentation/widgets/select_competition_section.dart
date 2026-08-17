import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import 'competition_section.enum.dart';

void selectCompetitionSection(
  BuildContext context, {
  required String competitionId,
  required CompetitionSection target,
  CompetitionSection? current,
}) {
  if (target == current) return;

  switch (target) {
    case CompetitionSection.leaderboard:
    case CompetitionSection.matches:
      context.pop();
    case CompetitionSection.players:
      context.pushReplacement(Routes.players(competitionId));
    case CompetitionSection.history:
      context.pushReplacement(Routes.history(competitionId));
    case CompetitionSection.configuration:
      context.pushReplacement(Routes.configuration(competitionId));
    case CompetitionSection.competitions:
      context.pushReplacement(Routes.home);
  }
}
