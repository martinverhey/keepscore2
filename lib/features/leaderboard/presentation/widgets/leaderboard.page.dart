import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/extensions/competition.extension.dart';
import '../../../../core/extensions/player_list.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/page_title.dart';
import '../../../../core/widgets/tag.dart';
import '../../../auth/presentation/cubit/auth_bloc.dart';
import '../../../competition/domain/competition.model.dart';
import '../../../competition/presentation/cubit/competition_cubit.dart';
import '../../../competition/presentation/widgets/competition_settings_button.dart';
import '../../../competition/presentation/pages/invite_sheet.dart';
import '../../../player/presentation/cubit/players_cubit.dart';
import '../../../profile/presentation/widgets/profile_section.dart';
import '../../domain/leaderboard.model.dart';
import '../cubit/leaderboard_cubit.dart';
import 'leaderboard_list.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key, required this.competitionId});

  final String competitionId;

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<LeaderboardCubit>().load();
  }

  Future<void> _refresh() => Future.wait([
    context.read<CompetitionCubit>().refresh(),
    context.read<PlayersCubit>().refresh(),
    context.read<LeaderboardCubit>().refresh(),
  ]);

  @override
  Widget build(BuildContext context) {
    final competitionCubit = context.watch<CompetitionCubit>();
    final competitionState = competitionCubit.state;
    final competition = competitionState.competition;
    final competitionId = widget.competitionId;
    final session = context.watch<AuthBloc>().state;
    final playersState = context.watch<PlayersCubit>().state;
    final myPlayerId = competitionState.myPlayerId;
    final myDisplayName = playersState is PlayersReady
        ? playersState.players.displayNameFor(myPlayerId)
        : null;

    setPageTitle(
      context,
      competition == null
          ? context.l10n.leaderboardTitle
          : '${competition.name} · ${context.l10n.leaderboardTitle}',
    );

    return AdaptiveScaffold(
      title: context.l10n.leaderboardTitle,
      onRefresh: _refresh,
      trailing: AppPlatform.useWideWeb(context)
          ? null
          : CompetitionSettingsButton(competitionId: competitionId),
      body: competition == null
          ? const AdaptiveLoader()
          : Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.xl,
              ),
              child: _content(
                context,
                competition,
                competitionId: competitionId,
                isOwner: competition.isOwnedBySession(session),
                myPlayerId: myPlayerId,
                myDisplayName: myDisplayName,
              ),
            ),
    );
  }

  Widget _content(
    BuildContext context,
    Competition competition, {
    required String competitionId,
    required bool isOwner,
    required String? myPlayerId,
    required String? myDisplayName,
  }) {
    final leaderboardState = context.watch<LeaderboardCubit>().state;
    final leaderboards = leaderboardState is LeaderboardReady
        ? leaderboardState.leaderboards
        : const <Leaderboard>[];
    Leaderboard? myLeaderboard;
    for (final leaderboard in leaderboards) {
      if (leaderboard.playerId == myPlayerId) {
        myLeaderboard = leaderboard;
        break;
      }
    }
    final myMedals = leaderboardState is LeaderboardReady
        ? leaderboardState.medals[myPlayerId]
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _competitionHeader(context, competition, competitionId),
        const SizedBox(height: AppSpacing.sm),
        if (myPlayerId != null && myDisplayName != null)
          ProfileSection(
            competitionId: competitionId,
            playerId: myPlayerId,
            displayName: myDisplayName,
            seasonLength: competition.seasonLength,
            leaderboard: myLeaderboard,
            medals: myMedals,
          ),
        const SizedBox(height: AppSpacing.lg),
        LeaderboardList(
          competitionId: competitionId,
          seasonLength: competition.seasonLength,
          myPlayerId: myPlayerId,
          isOwner: isOwner,
          onManagePlayers: () =>
              context.push<Object?>(Routes.players(competitionId)),
        ),
      ],
    );
  }

  Widget _competitionHeader(
    BuildContext context,
    Competition competition,
    String competitionId,
  ) {
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: _competitionButton(context, competition, competitionId),
          ),
        ),
        _inviteButton(context, competition.joinCode),
        const SizedBox(width: AppSpacing.xs),
        Tag(
          competition.joinCode,
          color: AdaptiveColors.accent(context),
          style: TagStyle.code,
        ),
      ],
    );
  }

  Widget _competitionButton(
    BuildContext context,
    Competition competition,
    String competitionId,
  ) {
    return AdaptiveTappable(
      onTap: () => context.go(Routes.competitions(competitionId)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              competition.name,
              style: AppTypography.bodyLarge.copyWith(color: AppColors.neutral),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          const AdaptiveIcon(
            AdaptiveGlyph.chevronRight,
            color: AppColors.neutral,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _inviteButton(BuildContext context, String joinCode) {
    return AdaptiveIconButton(
      glyph: AdaptiveGlyph.invite,
      semanticLabel: context.l10n.competitionInviteAction,
      onPressed: () => showInviteSheet(context, code: joinCode),
    );
  }
}
