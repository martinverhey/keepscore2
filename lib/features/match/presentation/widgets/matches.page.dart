import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/error/failure_messages.dart';
import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/extensions/competition.extension.dart';
import '../../../../core/extensions/game_type.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/content_scroll_view.dart';
import '../../../../core/widgets/hint_card.dart';
import '../../../../core/widgets/page_title.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/cubit/auth_bloc.dart';
import '../../../auth/presentation/widgets/guest_notice.dart';
import '../../../competition/presentation/cubit/competition_cubit.dart';
import '../../../competition/presentation/widgets/competition_settings_button.dart';
import '../../../competition/presentation/widgets/competition_tab.enum.dart';
import '../../../competition/presentation/widgets/competition_tab_bar.dart';
import '../../../player/presentation/cubit/players_cubit.dart';
import '../cubit/game_type_filter_cubit.dart';
import '../cubit/match_list_cubit.dart';
import 'day_header.dart';
import 'game_type_filter_dropdown.dart';
import 'match_day_group.dart';
import 'match_tile.dart';

class MatchesPage extends StatefulWidget {
  const MatchesPage({super.key});

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> {
  @override
  void initState() {
    super.initState();
    context.read<MatchListCubit>().load();
  }

  Future<void> _refresh() => Future.wait([
    context.read<CompetitionCubit>().refresh(),
    context.read<PlayersCubit>().refresh(),
    context.read<MatchListCubit>().refresh(),
  ]);

  @override
  Widget build(BuildContext context) {
    final competitionCubit = context.watch<CompetitionCubit>();
    final competitionState = competitionCubit.state;
    final competition = competitionState.competition;
    final competitionId = competitionCubit.competitionId!;
    final session = context.watch<AuthBloc>().state;
    final playersState = context.watch<PlayersCubit>().state;
    final isRegistered = session.canWrite;
    final isOwner = competition.isOwnedBySession(session);
    final hasPlayers =
        playersState is PlayersReady && playersState.active.length >= 2;
    final myPlayerId = competitionState.myPlayerId;

    setPageTitle(
      context,
      competition == null
          ? context.l10n.matchesTitle
          : '${competition.name} · ${context.l10n.matchesTitle}',
    );

    return AdaptiveScaffold(
      title: context.l10n.matchesTitle,
      onRefresh: _refresh,
      hasScrollBody: true,
      trailing: _trailing(context, competitionId),
      bottomBar: AppPlatform.useWideWeb(context)
          ? null
          : CompetitionTabBar(
              competitionId: competitionId,
              current: CompetitionTab.matches,
              isRegistered: isRegistered,
            ),
      body: ContentScrollView(
        child: BlocBuilder<MatchListCubit, MatchListState>(
          builder: (context, state) => _body(
            context,
            state,
            competitionId: competitionId,
            isRegistered: isRegistered,
            isOwner: isOwner,
            hasPlayers: hasPlayers,
            myPlayerId: myPlayerId,
          ),
        ),
      ),
    );
  }

  Widget _trailing(BuildContext context, String competitionId) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GameTypeFilterDropdown(
            selected: context.watch<GameTypeFilterCubit>().state,
            onSelected: context.read<GameTypeFilterCubit>().select,
          ),
          if (!AppPlatform.useWideWeb(context)) ...[
            const SizedBox(width: AppSpacing.xs),
            CompetitionSettingsButton(competitionId: competitionId),
          ],
        ],
      ),
    );
  }

  Widget _body(
    BuildContext context,
    MatchListState state, {
    required String competitionId,
    required bool isRegistered,
    required bool isOwner,
    required bool hasPlayers,
    required String? myPlayerId,
  }) {
    final cubit = context.read<MatchListCubit>();

    return switch (state) {
      MatchListLoading() => const Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: AdaptiveLoader(),
      ),
      MatchListFailed(:final failure) => ErrorRetry(
        message: failure.localized(context.l10n),
        retryLabel: context.l10n.commonRetry,
        onRetry: cubit.load,
      ),
      MatchListReady() => _list(
        context,
        state,
        cubit,
        competitionId: competitionId,
        isRegistered: isRegistered,
        isOwner: isOwner,
        hasPlayers: hasPlayers,
        myPlayerId: myPlayerId,
      ),
    };
  }

  Widget _list(
    BuildContext context,
    MatchListReady state,
    MatchListCubit cubit, {
    required String competitionId,
    required bool isRegistered,
    required bool isOwner,
    required bool hasPlayers,
    required String? myPlayerId,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isRegistered)
          GuestNotice(message: context.l10n.matchGuestCannotLog),
        if (isRegistered && hasPlayers) _needsPlayersHint(context),
        const SizedBox(height: AppSpacing.lg),
        _matchesSection(
          context,
          state,
          competitionId: competitionId,
          isOwner: isOwner,
          myPlayerId: myPlayerId,
        ),
        if (state.hasMore) _loadMoreButton(context, state, cubit),
        if (state.actionFailure != null) _actionFailureText(context, state),
      ],
    );
  }

  Widget _needsPlayersHint(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Text(context.l10n.matchNeedsPlayers, style: AppTypography.caption),
    );
  }

  Widget _matchesSection(
    BuildContext context,
    MatchListReady state, {
    required String competitionId,
    required bool isOwner,
    required String? myPlayerId,
  }) {
    if (state.busy) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: AdaptiveLoader(),
      );
    }

    if (state.matches.isEmpty) {
      return _emptyState(
        context,
        state,
        competitionId: competitionId,
        isOwner: isOwner,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final group in groupByDay(state.matches)) ...[
          DayHeader(day: group.day),
          for (final match in group.matches)
            MatchTile(
              match: match,
              myPlayerId: myPlayerId,
              onTap: () =>
                  context.push<Object?>(Routes.match(competitionId, match.id)),
            ),
        ],
      ],
    );
  }

  Widget _emptyState(
    BuildContext context,
    MatchListReady state, {
    required String competitionId,
    required bool isOwner,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EmptyState(
          message: state.selectedGameType == null
              ? context.l10n.matchesEmpty
              : context.l10n.matchesFilterEmpty(
                  state.selectedGameType!.label(context),
                ),
        ),
        if (isOwner && state.selectedGameType == null) ...[
          const SizedBox(height: AppSpacing.sm),
          HintCard(
            message: context.l10n.matchesCreateHint,
            actionLabel: context.l10n.matchesCreateHintAction,
            onAction: () =>
                context.push<Object?>(Routes.newMatch(competitionId)),
          ),
        ],
      ],
    );
  }

  Widget _loadMoreButton(
    BuildContext context,
    MatchListReady state,
    MatchListCubit cubit,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: AdaptiveButton(
        label: context.l10n.matchLoadMore,
        kind: AdaptiveButtonKind.plain,
        busy: state.loadingMore,
        onPressed: cubit.loadMore,
      ),
    );
  }

  Widget _actionFailureText(BuildContext context, MatchListReady state) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Text(
        state.actionFailure!.localized(context.l10n),
        style: const TextStyle(color: AppColors.negative),
      ),
    );
  }
}
