import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure_messages.dart';
import '../../../../core/extensions/build_context_l10n.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../leaderboard/domain/leaderboard.model.dart';
import '../../../leaderboard/presentation/widgets/game_type_filter_dropdown.dart';
import '../../../leaderboard/presentation/widgets/leaderboard_row.dart';
import '../../../leaderboard/presentation/widgets/season_dropdown.dart';
import '../../../profile/presentation/widgets/game_type_label.dart';
import '../../domain/competition.model.dart';
import '../cubit/competition_detail_cubit.dart';
import '../cubit/season_history_cubit.dart';

class SeasonHistoryPage extends StatefulWidget {
  const SeasonHistoryPage({super.key});

  @override
  State<SeasonHistoryPage> createState() => _SeasonHistoryPageState();
}

class _SeasonHistoryPageState extends State<SeasonHistoryPage> {
  @override
  void initState() {
    super.initState();
    context.read<CompetitionDetailCubit>().load();
    context.read<SeasonHistoryCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final competition = context
        .watch<CompetitionDetailCubit>()
        .state
        .competition;
    final myPlayerId = context.watch<CompetitionDetailCubit>().state.myPlayerId;
    final seasonLength = competition?.seasonLength;

    return BlocBuilder<SeasonHistoryCubit, SeasonHistoryState>(
      builder: (context, state) {
        final cubit = context.read<SeasonHistoryCubit>();

        return AdaptiveScaffold(
          title: context.l10n.seasonHistoryTitle,
          trailing: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: GameTypeFilterDropdown(
              selected: state.selectedGameType,
              onSelected: cubit.selectGameTypeFilter,
            ),
          ),
          hasScrollBody: true,
          body: switch (state.status) {
            SeasonHistoryStatus.loading => const AdaptiveLoader(),
            SeasonHistoryStatus.failed => ErrorRetry(
              message: state.failure!.localized(context.l10n),
              retryLabel: context.l10n.commonRetry,
              onRetry: cubit.load,
            ),
            SeasonHistoryStatus.ready when seasonLength == null =>
              const AdaptiveLoader(),
            SeasonHistoryStatus.ready => _ready(
              context,
              state,
              cubit,
              cubit.competitionId,
              myPlayerId,
              seasonLength!,
            ),
          },
        );
      },
    );
  }

  Widget _ready(
    BuildContext context,
    SeasonHistoryState state,
    SeasonHistoryCubit cubit,
    String competitionId,
    String? myPlayerId,
    SeasonLength seasonLength,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.selectedSeason != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              0,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SeasonDropdown(
                seasons: state.seasons,
                selected: state.selectedSeason!,
                seasonLength: seasonLength,
                onSelected: cubit.selectSeason,
              ),
            ),
          ),
        Expanded(
          child: _content(
            context,
            state,
            competitionId,
            myPlayerId,
            seasonLength,
          ),
        ),
      ],
    );
  }

  Widget _content(
    BuildContext context,
    SeasonHistoryState state,
    String competitionId,
    String? myPlayerId,
    SeasonLength seasonLength,
  ) {
    if (state.busy) return const Center(child: AdaptiveLoader());

    if (state.standings.isEmpty) {
      return EmptyState(
        message: state.selectedGameType == null
            ? context.l10n.seasonHistoryEmpty
            : context.l10n.seasonHistoryFilterEmpty(
                gameTypeLabel(context, state.selectedGameType!),
              ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        for (final standing in state.standings)
          LeaderboardRow(
            competitionId: competitionId,
            leaderboard: Leaderboard.fromSeasonStanding(standing),
            isMe: standing.playerId == myPlayerId,
            myPlayerId: myPlayerId,
            seasonLength: seasonLength,
          ),
      ],
    );
  }
}
