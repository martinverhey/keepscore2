import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/error/failure_messages.dart';
import '../../../../core/extensions/box_constraints.extension.dart';
import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/extensions/game_type.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/page_title.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/cubit/auth_bloc.dart';
import '../../../competition/domain/competition.model.dart';
import '../../../competition/presentation/cubit/competition_cubit.dart';
import '../../../competition/presentation/widgets/competition_section.enum.dart';
import '../../../competition/presentation/widgets/home_sidebar_competition.dart';
import '../../../competition/presentation/widgets/open_home.dart';
import '../../../competition/presentation/widgets/open_theme.dart';
import '../../../competition/presentation/widgets/select_competition_section.dart';
import '../../../competition/presentation/widgets/sidebar.dart';
import '../../../leaderboard/domain/leaderboard.model.dart';
import '../../../leaderboard/presentation/widgets/game_type_filter_dropdown.dart';
import '../../../leaderboard/presentation/widgets/leaderboard_row.dart';
import '../../../leaderboard/presentation/widgets/season_dropdown.dart';
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

  void _selectSection(CompetitionSection section) => selectCompetitionSection(
    context,
    competitionId: context.read<HistoryCubit>().competitionId,
    current: CompetitionSection.history,
    target: section,
  );

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthBloc>().state;
    final competition = context.watch<CompetitionCubit>().state.competition;
    final myPlayerId = context.watch<CompetitionCubit>().state.myPlayerId;
    final seasonLength = competition?.seasonLength;
    final isOwner =
        session.canWrite &&
        session.user?.id != null &&
        session.user?.id == competition?.ownerId;

    return BlocBuilder<HistoryCubit, HistoryState>(
      builder: (context, state) {
        final cubit = context.read<HistoryCubit>();
        final selectedGameType = switch (state) {
          HistoryLoading(:final selectedGameType) => selectedGameType,
          HistoryFailed(:final selectedGameType) => selectedGameType,
          HistoryReady(:final selectedGameType) => selectedGameType,
        };
        setPageTitle(context, context.l10n.historyTitle);

        return Sidebar(
          competitionName: competition?.name,
          current: CompetitionSection.history,
          canManageSettings: isOwner,
          isRegistered: session.canWrite,
          onSelectSection: _selectSection,
          onNewMatch: () =>
              context.push<Object?>(Routes.newMatch(cubit.competitionId)),
          onOpenHome: () => openHome(
            context,
            replace: true,
            competitionId: cubit.competitionId,
            competitionName: competition?.name,
            canManageSettings: isOwner,
          ),
          onOpenTheme: () => openTheme(
            context,
            replace: true,
            sidebarCompetition: HomeSidebarCompetition(
              competitionId: cubit.competitionId,
              competitionName: competition?.name,
              canManageSettings: isOwner,
            ),
          ),
          onSignOut: () =>
              context.read<AuthBloc>().add(const AuthSignOutRequested()),
          child: AdaptiveScaffold(
            title: context.l10n.historyTitle,
            trailing: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: GameTypeFilterDropdown(
                selected: selectedGameType,
                onSelected: cubit.selectGameTypeFilter,
              ),
            ),
            hasScrollBody: true,
            body: switch (state) {
              HistoryLoading() => const AdaptiveLoader(),
              HistoryFailed(:final failure) => ErrorRetry(
                message: failure.localized(context.l10n),
                retryLabel: context.l10n.commonRetry,
                onRetry: cubit.load,
              ),
              HistoryReady() when seasonLength == null =>
                const AdaptiveLoader(),
              HistoryReady() => _ready(
                context,
                state,
                cubit,
                cubit.competitionId,
                myPlayerId,
                seasonLength!,
              ),
            },
          ),
        );
      },
    );
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
            if (state.selectedSeason != null)
              Padding(
                padding: EdgeInsets.fromLTRB(inset, AppSpacing.md, inset, 0),
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
      return EmptyState(
        message: state.selectedGameType == null
            ? context.l10n.historyEmpty
            : context.l10n.historyFilterEmpty(
                state.selectedGameType!.label(context),
              ),
      );
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
          ),
      ],
    );
  }
}
