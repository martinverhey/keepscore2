import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import 'home_sidebar_competition.dart';

void openHome(
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
  if (replace) {
    context.pushReplacement(Routes.home, extra: extra);
  } else {
    context.push(Routes.home, extra: extra);
  }
}
