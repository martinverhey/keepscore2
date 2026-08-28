import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/competition.extension.dart';
import '../../../auth/presentation/cubit/auth_bloc.dart';
import '../cubit/competition_cubit.dart';

class HomeSidebarCompetition {
  const HomeSidebarCompetition({
    required this.competitionId,
    required this.competitionName,
    required this.canManageSettings,
  });

  factory HomeSidebarCompetition.of(
    BuildContext context,
    String competitionId, {
    bool listen = true,
  }) {
    final competition = listen
        ? context.watch<CompetitionCubit>().state.competition
        : context.read<CompetitionCubit>().state.competition;
    final session = listen
        ? context.watch<AuthBloc>().state
        : context.read<AuthBloc>().state;

    return HomeSidebarCompetition(
      competitionId: competitionId,
      competitionName: competition?.name,
      canManageSettings:
          session.canWrite && competition.isOwnedBySession(session),
    );
  }

  final String competitionId;
  final String? competitionName;
  final bool canManageSettings;
}
