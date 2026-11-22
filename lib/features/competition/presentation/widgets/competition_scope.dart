import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/competition_cubit.dart';

class CompetitionScope extends StatefulWidget {
  const CompetitionScope({
    super.key,
    required this.competitionId,
    required this.child,
  });

  final String competitionId;
  final Widget child;

  @override
  State<CompetitionScope> createState() => _CompetitionScopeState();
}

class _CompetitionScopeState extends State<CompetitionScope> {
  @override
  void initState() {
    super.initState();
    _select();
  }

  @override
  void didUpdateWidget(CompetitionScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.competitionId == oldWidget.competitionId) return;
    _select();
  }

  void _select() {
    context.read<CompetitionCubit>().select(widget.competitionId);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
