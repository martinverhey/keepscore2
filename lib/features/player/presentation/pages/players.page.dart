import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/extensions/build_context_l10n.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/page_title.dart';
import '../../../auth/presentation/cubit/auth_bloc.dart';
import '../../../competition/presentation/cubit/competition_detail_cubit.dart';
import '../../../competition/presentation/widgets/competition_section.enum.dart';
import '../../../competition/presentation/widgets/competition_shell.dart';
import '../cubit/players_cubit.dart';
import '../widgets/players.dart';

class PlayersPage extends StatefulWidget {
  const PlayersPage({super.key});

  @override
  State<PlayersPage> createState() => _PlayersPageState();
}

class _PlayersPageState extends State<PlayersPage> {
  @override
  void initState() {
    super.initState();
    context.read<CompetitionDetailCubit>().load();
    context.read<PlayersCubit>().load();
  }

  void _selectSection(CompetitionSection section) {
    final competitionId = context.read<PlayersCubit>().competitionId;
    switch (section) {
      case CompetitionSection.leaderboard:
      case CompetitionSection.matches:
        context.pop();
      case CompetitionSection.players:
        break;
      case CompetitionSection.history:
        context.pushReplacement(Routes.history(competitionId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthBloc>().state;
    final competition = context
        .watch<CompetitionDetailCubit>()
        .state
        .competition;
    final isOwner =
        session.canWrite &&
        session.user?.id != null &&
        session.user?.id == competition?.ownerId;
    final competitionId = context.read<PlayersCubit>().competitionId;
    setPageTitle(context, context.l10n.playersTitle);

    return CompetitionShell(
      competitionName: competition?.name,
      current: CompetitionSection.players,
      canManageSettings: isOwner,
      isRegistered: session.canWrite,
      onSelectSection: _selectSection,
      onNewMatch: () => context.push<bool>(Routes.newMatch(competitionId)),
      onOpenHome: () => context.push(Routes.home),
      onOpenSettings: () =>
          context.push(Routes.competitionSettings(competitionId)),
      onOpenTheme: () => context.push(Routes.theme),
      onSignOut: () =>
          context.read<AuthBloc>().add(const AuthSignOutRequested()),
      child: AdaptiveScaffold(
        title: context.l10n.playersTitle,
        trailing: isOwner
            ? AdaptiveIconButton(
                glyph: AdaptiveGlyph.add,
                semanticLabel: context.l10n.playersAddDummy,
                onPressed: () => addPlaceholderPlayer(context),
              )
            : null,
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Players(
            ownerUserId: competition?.ownerId,
            myUserId: session.user?.id,
            isRegistered: session.canWrite,
          ),
        ),
      ),
    );
  }
}
