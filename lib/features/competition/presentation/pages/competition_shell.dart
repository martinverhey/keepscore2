import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/data/recent_competition_store.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../auth/presentation/cubit/auth_bloc.dart';
import '../../../player/presentation/cubit/players_cubit.dart';
import '../cubit/competition_cubit.dart';
import '../widgets/competition_tab.enum.dart';
import '../widgets/competition_tab_bar.dart';

class CompetitionShell extends StatefulWidget {
  const CompetitionShell({
    super.key,
    required this.competitionId,
    required this.navigationShell,
  });

  final String competitionId;
  final StatefulNavigationShell navigationShell;

  @override
  State<CompetitionShell> createState() => _CompetitionShellState();
}

class _CompetitionShellState extends State<CompetitionShell> {
  @override
  void initState() {
    super.initState();
    _enterCompetition();
  }

  @override
  void didUpdateWidget(CompetitionShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.competitionId == oldWidget.competitionId) return;
    _enterCompetition();
  }

  void _enterCompetition() {
    RecentCompetitionStore.set(widget.competitionId);
    context.read<PlayersCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CompetitionCubit, CompetitionState>(
      listener: (context, state) {
        if (state is CompetitionMissing) {
          RecentCompetitionStore.clear();
          context.go(Routes.home);
        }
      },
      child: AdaptiveBottomBarHost(
        bar: _bar(context),
        child: widget.navigationShell,
      ),
    );
  }

  Widget? _bar(BuildContext context) {
    if (AppPlatform.useWideWeb(context)) return null;
    return CompetitionTabBar(
      competitionId: widget.competitionId,
      current: widget.navigationShell.currentIndex == 0
          ? CompetitionTab.leaderboard
          : CompetitionTab.matches,
      isRegistered: context.watch<AuthBloc>().state.canWrite,
    );
  }
}
