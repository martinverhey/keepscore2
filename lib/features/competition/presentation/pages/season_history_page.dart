import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure_messages.dart';
import '../../../../core/extensions/build_context_l10n.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/rating_delta.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../leaderboard/domain/medal.dart';
import '../../../leaderboard/domain/season_standing.dart';
import '../../../leaderboard/presentation/widgets/game_type_filter_bar.dart';
import '../../../leaderboard/presentation/widgets/season_label.dart';
import '../../../profile/presentation/widgets/game_type_label.dart';
import '../../domain/competition.dart';
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
    final seasonLength = context
        .watch<CompetitionDetailCubit>()
        .state
        .competition
        ?.seasonLength;

    return BlocBuilder<SeasonHistoryCubit, SeasonHistoryState>(
      builder: (context, state) {
        final cubit = context.read<SeasonHistoryCubit>();

        return AdaptiveScaffold(
          title: context.l10n.seasonHistoryTitle,
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
    SeasonLength seasonLength,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            0,
          ),
          child: GameTypeFilterBar(
            selected: state.selectedGameType,
            onSelected: cubit.selectGameTypeFilter,
          ),
        ),
        Expanded(child: _groupList(context, state, seasonLength)),
      ],
    );
  }

  Widget _groupList(
    BuildContext context,
    SeasonHistoryState state,
    SeasonLength seasonLength,
  ) {
    if (state.busy) return const Center(child: AdaptiveLoader());

    if (state.groups.isEmpty) {
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
        for (final group in state.groups) _seasonCard(context, group, seasonLength),
      ],
    );
  }

  Widget _seasonCard(
    BuildContext context,
    SeasonHistoryGroup group,
    SeasonLength seasonLength,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: AppRadius.card,
        color: AppColors.neutral.withValues(alpha: 0.08),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            seasonLabel(context, group.standings.first.season, seasonLength),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final standing in group.standings)
            _playerRow(context, standing),
        ],
      ),
    );
  }

  Widget _playerRow(BuildContext context, SeasonStanding standing) {
    final medal = standing.medal;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${standing.rank}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: medal == null ? AppColors.neutral : _medalColor(medal),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          if (medal != null) ...[
            AdaptiveIcon(AdaptiveGlyph.medal, color: _medalColor(medal), size: 16),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Text(
              standing.displayName,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            formatRating(standing.rating),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Color _medalColor(Medal medal) => switch (medal) {
    Medal.gold => AppColors.gold,
    Medal.silver => AppColors.silver,
    Medal.bronze => AppColors.bronze,
  };
}
