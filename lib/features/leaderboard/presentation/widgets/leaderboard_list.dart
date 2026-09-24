import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure_messages.dart';
import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/extensions/date_time.extension.dart';
import '../../../../core/extensions/season.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/list_header.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../competition/domain/competition.model.dart';
import '../../domain/season.model.dart';
import '../cubit/leaderboard_cubit.dart';
import '../pages/season_sheet.dart';
import 'leaderboard_row.dart';

class LeaderboardList extends StatelessWidget {
  const LeaderboardList({
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
      LeaderboardReady() => _list(context, state, cubit),
    };
  }

  Widget _list(
    BuildContext context,
    LeaderboardReady state,
    LeaderboardCubit cubit,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _seasonBar(context, state, cubit),
        const SizedBox(height: AppSpacing.md),
        _players(context, state),
      ],
    );
  }

  Widget _seasonBar(
    BuildContext context,
    LeaderboardReady state,
    LeaderboardCubit cubit,
  ) {
    if (!isOwner) return _seasonHeader(context, state, cubit);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(child: _seasonHeader(context, state, cubit)),
        _manageButton(context),
      ],
    );
  }

  Widget _seasonHeader(
    BuildContext context,
    LeaderboardReady state,
    LeaderboardCubit cubit,
  ) {
    final season = state.viewedSeason;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: ListHeader(
        title: season.label(context, seasonLength),
        subtitle: _seasonSubtitle(context, state, season),
        semanticLabel: context.l10n.leaderboardPickSeason,
        onTap: state.hasHistory
            ? () => _pickSeason(context, state, cubit)
            : null,
      ),
    );
  }

  String _seasonSubtitle(
    BuildContext context,
    LeaderboardReady state,
    Season season,
  ) {
    if (state.viewedFinishedSeason != null) return season.rangeLabel(context);
    return context.l10n.leaderboardSeasonEnds(
      season.endsAt.shortDayLabel(context),
    );
  }

  Future<void> _pickSeason(
    BuildContext context,
    LeaderboardReady state,
    LeaderboardCubit cubit,
  ) async {
    final picked = await showAdaptiveSheet<Season>(
      context,
      builder: (_) => SeasonSheet(
        seasons: state.pickableSeasons,
        selected: state.viewedSeason,
        seasonLength: seasonLength,
      ),
    );
    if (picked == null) return;
    await cubit.viewSeason(picked == state.season ? null : picked.id);
  }

  Widget _manageButton(BuildContext context) {
    return AdaptiveButton(
      label: context.l10n.leaderboardManage,
      kind: AdaptiveButtonKind.plain,
      expand: false,
      onPressed: onManagePlayers,
    );
  }

  Widget _players(BuildContext context, LeaderboardReady state) {
    if (state.busy) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: AdaptiveLoader(),
      );
    }

    final leaderboards = state.viewedLeaderboards;
    if (leaderboards.isEmpty) {
      return EmptyState(message: context.l10n.leaderboardNoPlayers);
    }

    final isCurrent = state.viewedFinishedSeason == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final leaderboard in leaderboards)
          LeaderboardRow(
            competitionId: competitionId,
            leaderboard: leaderboard,
            isMe: leaderboard.playerId == myPlayerId,
            myPlayerId: myPlayerId,
            seasonLength: seasonLength,
            medals: isCurrent ? state.medals[leaderboard.playerId] : null,
            opensProfile: isCurrent,
          ),
      ],
    );
  }
}
