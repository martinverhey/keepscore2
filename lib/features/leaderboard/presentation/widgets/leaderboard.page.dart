import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/tag.dart';
import '../../../competition/domain/competition.model.dart';
import '../../../competition/presentation/widgets/invite_sheet.dart';
import '../../../profile/presentation/widgets/profile_section.dart';
import '../../domain/leaderboard.model.dart';
import '../cubit/leaderboard_cubit.dart';
import 'leaderboard_list.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({
    super.key,
    required this.competitionId,
    required this.competition,
    required this.isOwner,
    required this.myPlayerId,
    required this.myDisplayName,
    required this.onManagePlayers,
    required this.onOpenCompetitions,
  });

  final String competitionId;
  final Competition competition;
  final bool isOwner;
  final String? myPlayerId;
  final String? myDisplayName;
  final VoidCallback onManagePlayers;
  final VoidCallback onOpenCompetitions;

  @override
  Widget build(BuildContext context) {
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
        _competitionHeader(context, competition),
        const SizedBox(height: AppSpacing.sm),
        if (myPlayerId != null && myDisplayName != null)
          ProfileSection(
            competitionId: competitionId,
            playerId: myPlayerId!,
            displayName: myDisplayName!,
            seasonLength: competition.seasonLength,
            leaderboard: myLeaderboard,
            medals: myMedals,
            playerCount: leaderboards.length,
          ),
        const SizedBox(height: AppSpacing.lg),
        LeaderboardList(
          competitionId: competitionId,
          seasonLength: competition.seasonLength,
          myPlayerId: myPlayerId,
          isOwner: isOwner,
          onManagePlayers: onManagePlayers,
        ),
      ],
    );
  }

  Widget _competitionHeader(BuildContext context, Competition competition) {
    return Row(
      children: [
        _competitionButton(context, competition),
        const SizedBox(width: AppSpacing.sm),
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

  Widget _competitionButton(BuildContext context, Competition competition) {
    return Expanded(
      child: AdaptiveTappable(
        onTap: onOpenCompetitions,
        child: Row(
          children: [
            Flexible(
              child: Text(
                competition.name,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.neutral,
                ),
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
