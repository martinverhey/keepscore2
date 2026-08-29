import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/data/recent_competition_store.dart';
import '../../../player/presentation/cubit/players_cubit.dart';
import '../cubit/competition_cubit.dart';

class CompetitionShell extends StatefulWidget {
  const CompetitionShell({
    super.key,
    required this.competitionId,
    required this.child,
  });

  final String competitionId;
  final Widget child;

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
      child: widget.child,
    );
  }
}
