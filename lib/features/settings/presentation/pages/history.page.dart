import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure_messages.dart';
import '../../../../core/extensions/box_constraints.extension.dart';
import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/extensions/season.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/page_title.dart';
import '../../../../core/widgets/list_header.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../competition/domain/competition.model.dart';
import '../../../competition/presentation/cubit/competition_cubit.dart';
import '../../../leaderboard/domain/leaderboard.model.dart';
import '../../../leaderboard/presentation/widgets/leaderboard_row.dart';
import '../../../leaderboard/presentation/widgets/season_filter_button.dart';
import '../cubit/history_cubit.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  void initState() {
    super.initState();
    context.read<HistoryCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final competition = context.watch<CompetitionCubit>().state.competition;
    final myPlayerId = context.watch<CompetitionCubit>().state.myPlayerId;
    final seasonLength = competition?.seasonLength;

    return BlocBuilder<HistoryCubit, HistoryState>(
      builder: (context, state) {
        final cubit = context.read<HistoryCubit>();
        setPageTitle(context, context.l10n.historyTitle);

        return AdaptiveScaffold(
          title: context.l10n.historyTitle,
          hasScrollBody: true,
          trailing: _seasonFilter(state, cubit, seasonLength),
          body: switch (state) {
            HistoryLoading() => const AdaptiveLoader(),
            HistoryFailed(:final failure) => ErrorRetry(
              message: failure.localized(context.l10n),
              retryLabel: context.l10n.commonRetry,
              onRetry: cubit.load,
            ),
            HistoryReady() when seasonLength == null => const AdaptiveLoader(),
            HistoryReady() => _ready(
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

  Widget? _seasonFilter(
    HistoryState state,
    HistoryCubit cubit,
    SeasonLength? seasonLength,
  ) {
    if (state is! HistoryReady || seasonLength == null) return null;
    if (state.selectedSeason case final season?) {
      return SeasonFilterButton(
        seasons: state.seasons,
        selected: season,
        seasonLength: seasonLength,
        onSelected: cubit.selectSeason,
      );
    }
    return null;
  }

  Widget _ready(
    BuildContext context,
    HistoryReady state,
    HistoryCubit cubit,
    String competitionId,
    String? myPlayerId,
    SeasonLength seasonLength,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final inset = constraints.contentHorizontalInset;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.selectedSeason case final season?)
              Padding(
                padding: EdgeInsets.fromLTRB(inset, AppSpacing.md, inset, 0),
                child: ListHeader(
                  title: season.label(context, seasonLength),
                  subtitle: season.rangeLabel(context),
                ),
              ),
            Expanded(
              child: _content(
                context,
                state,
                competitionId,
                myPlayerId,
                seasonLength,
                inset,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _content(
    BuildContext context,
    HistoryReady state,
    String competitionId,
    String? myPlayerId,
    SeasonLength seasonLength,
    double horizontalInset,
  ) {
    if (state.busy) return const Center(child: AdaptiveLoader());

    if (state.leaderboards.isEmpty) {
      return EmptyState(message: context.l10n.historyEmpty);
    }

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalInset,
        vertical: AppSpacing.md,
      ),
      children: [
        for (final leaderboard in state.leaderboards)
          LeaderboardRow(
            competitionId: competitionId,
            leaderboard: Leaderboard.fromSeasonLeaderboard(leaderboard),
            isMe: leaderboard.playerId == myPlayerId,
            myPlayerId: myPlayerId,
            seasonLength: seasonLength,
            opensProfile: false,
          ),
      ],
    );
  }
}
