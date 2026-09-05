import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/data/recent_competition_store.dart';
import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/extensions/competition_tab.extension.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/swipe_navigator.dart';
import '../../../auth/presentation/cubit/auth_bloc.dart';
import '../../../match/presentation/pages/new_match_sheet.dart';
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
        action: _newMatch(context),
        child: _swipeableShell(context),
      ),
    );
  }

  Widget? _bar(BuildContext context) {
    if (AppPlatform.useWideWeb(context)) return null;
    return CompetitionTabBar(
      competitionId: widget.competitionId,
      current: _current,
      isRegistered: _canWrite(context),
    );
  }

  AdaptiveBottomBarAction? _newMatch(BuildContext context) {
    if (AppPlatform.useWideWeb(context) || !_canWrite(context)) return null;
    return AdaptiveBottomBarAction(
      glyph: AdaptiveGlyph.add,
      label: context.l10n.matchNew,
      onPressed: () =>
          showNewMatchSheet(context, competitionId: widget.competitionId),
    );
  }

  Widget _swipeableShell(BuildContext context) {
    return SwipeNavigator(
      onNext: _goToTab(context, _current.index + 1),
      onPrevious: _goToTab(context, _current.index - 1),
      child: widget.navigationShell,
    );
  }

  VoidCallback? _goToTab(BuildContext context, int index) {
    if (index < 0 || index >= CompetitionTab.values.length) return null;
    final tab = CompetitionTab.values[index];
    return () => context.go(tab.route(widget.competitionId));
  }

  CompetitionTab get _current =>
      CompetitionTab.values[widget.navigationShell.currentIndex];

  bool _canWrite(BuildContext context) =>
      context.watch<AuthBloc>().state.canWrite;
}
