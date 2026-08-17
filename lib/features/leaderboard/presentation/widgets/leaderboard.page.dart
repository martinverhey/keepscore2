import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/error/failure_messages.dart';
import '../../../../core/extensions/build_context_l10n.dart';
import '../../../../core/extensions/build_context_locale.dart';
import '../../../../core/extensions/game_type_label.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../competition/domain/competition.model.dart';
import '../../domain/season.model.dart';
import '../cubit/leaderboard_cubit.dart';
import 'leaderboard_row.dart';
import 'season_label.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({
    super.key,
    required this.competitionId,
    required this.seasonLength,
    required this.myPlayerId,
    required this.isOwner,
    required this.onManagePlayers,
  });

  final String competitionId;
  final SeasonLength seasonLength;
  final String? myPlayerId;
  final bool isOwner;
  final VoidCallback onManagePlayers;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LeaderboardCubit>();

    return BlocBuilder<LeaderboardCubit, LeaderboardState>(
      builder: (context, state) => _body(context, state, cubit),
    );
  }

  Widget _body(
    BuildContext context,
    LeaderboardState state,
    LeaderboardCubit cubit,
  ) {
    return switch (state) {
      LeaderboardLoading() => const Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: AdaptiveLoader(),
      ),
      LeaderboardFailed(:final failure) => ErrorRetry(
        message: failure.localized(context.l10n),
        retryLabel: context.l10n.commonRetry,
        onRetry: cubit.load,
      ),
      LeaderboardReady() => _list(context, state),
    };
  }

  Widget _list(BuildContext context, LeaderboardReady state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _seasonBar(context, state.season),
        const SizedBox(height: AppSpacing.md),
        _rows(context, state),
        if (isOwner) _manageButton(context),
      ],
    );
  }

  Widget _rows(BuildContext context, LeaderboardReady state) {
    if (state.busy) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: AdaptiveLoader(),
      );
    }

    if (state.leaderboards.isEmpty) {
      return EmptyState(
        message: state.selectedGameType == null
            ? context.l10n.leaderboardNoPlayers
            : context.l10n.leaderboardFilterEmpty(
                state.selectedGameType!.label(context),
              ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final leaderboard in state.leaderboards)
          LeaderboardRow(
            competitionId: competitionId,
            leaderboard: leaderboard,
            isMe: leaderboard.playerId == myPlayerId,
            myPlayerId: myPlayerId,
            seasonLength: seasonLength,
            medals: state.medals[leaderboard.playerId],
          ),
      ],
    );
  }

  Widget _manageButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: AdaptiveButton(
        label: context.l10n.playersManageTitle,
        kind: AdaptiveButtonKind.tinted,
        onPressed: onManagePlayers,
      ),
    );
  }

  Widget _seasonBar(BuildContext context, Season season) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          seasonLabel(context, season, seasonLength),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          context.l10n.leaderboardSeasonEnds(
            DateFormat.MMMd(context.languageTag).format(season.endsAt),
          ),
          style: const TextStyle(color: AppColors.neutral, fontSize: 12),
        ),
      ],
    );
  }
}
