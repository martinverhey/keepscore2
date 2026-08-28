import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../cubit/competition_cubit.dart';
import 'sidebar.dart';
import 'sidebar_section.enum.dart';

class SidebarShell extends StatelessWidget {
  const SidebarShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Sidebar(
      current: _current(context),
      onSelectSection: (section) => _select(context, section),
      child: child,
    );
  }

  SidebarSection? _current(BuildContext context) {
    if (location == Routes.home) return SidebarSection.competitions;
    if (location == Routes.language) return SidebarSection.language;
    if (location.endsWith('/settings/players')) return SidebarSection.players;
    if (location.endsWith('/settings/history')) return SidebarSection.history;
    if (location.endsWith('/settings/configuration')) {
      return SidebarSection.configuration;
    }
    if (location.endsWith('/match/new')) return SidebarSection.newMatch;
    if (location.endsWith('/settings')) return null;
    if (location.contains('/match/')) return SidebarSection.matches;
    if (location.endsWith('/matches')) return SidebarSection.matches;
    if (location.endsWith('/leaderboard')) return SidebarSection.leaderboard;

    return null;
  }

  void _select(BuildContext context, SidebarSection section) {
    final route = _routeFor(context, section);
    if (route == null) return;

    context.read<CompetitionCubit>().refresh();
    context.go(route);
  }

  String? _routeFor(BuildContext context, SidebarSection section) {
    if (section == SidebarSection.competitions) return Routes.home;
    if (section == SidebarSection.language) return Routes.language;

    final competitionId = context.read<CompetitionCubit>().competitionId;
    if (competitionId == null) return null;

    return switch (section) {
      SidebarSection.leaderboard => Routes.leaderboard(competitionId),
      SidebarSection.matches => Routes.matches(competitionId),
      SidebarSection.newMatch => Routes.newMatch(competitionId),
      SidebarSection.players => Routes.players(competitionId),
      SidebarSection.history => Routes.history(competitionId),
      SidebarSection.configuration => Routes.configuration(competitionId),
      SidebarSection.competitions || SidebarSection.language => null,
    };
  }
}
