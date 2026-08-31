import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure_messages.dart';
import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/extensions/game_type.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/curved_arrow.dart';
import '../../../../core/widgets/curved_arrow_direction.enum.dart';
import '../../../../core/widgets/page_title.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/cubit/auth_bloc.dart';
import '../../../auth/presentation/widgets/guest_notice.dart';
import '../../../competition/presentation/cubit/competition_cubit.dart';
import '../../../competition/presentation/widgets/competition_settings_button.dart';
import '../../../player/presentation/cubit/players_cubit.dart';
import '../../domain/match_entry.model.dart';
import '../cubit/game_type_filter_cubit.dart';
import '../cubit/match_list_cubit.dart';
import 'day_header.dart';
import 'game_type_filter_dropdown.dart';
import 'match_day_group.dart';
import 'match_card.dart';
import 'match_detail_sheet.dart';

class MatchesPage extends StatefulWidget {
  const MatchesPage({super.key, required this.competitionId});

  final String competitionId;

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
    final competitionId = widget.competitionId;
    final session = context.watch<AuthBloc>().state;
    final playersState = context.watch<PlayersCubit>().state;
    final isRegistered = session.canWrite;
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
      trailing: _trailing(context, competitionId),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.xl,
          ),
          sliver: BlocBuilder<MatchListCubit, MatchListState>(
            builder: (context, state) => _body(
              context,
              state,
              competitionId: competitionId,
              isRegistered: isRegistered,
              hasPlayers: hasPlayers,
              myPlayerId: myPlayerId,
            ),
          ),
        ),
      ],
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
            const SizedBox(width: AppSpacing.sm),
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
    required bool hasPlayers,
    required String? myPlayerId,
  }) {
    final cubit = context.read<MatchListCubit>();

    return switch (state) {
      MatchListLoading() => _loader(),
      MatchListFailed(:final failure) => SliverToBoxAdapter(
        child: ErrorRetry(
          message: failure.localized(context.l10n),
          retryLabel: context.l10n.commonRetry,
          onRetry: cubit.load,
        ),
      ),
      MatchListReady() => _list(
        context,
        state,
        cubit,
        competitionId: competitionId,
        isRegistered: isRegistered,
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
    required bool hasPlayers,
    required String? myPlayerId,
  }) {
    return SliverMainAxisGroup(
      slivers: [
        if (!isRegistered)
          SliverToBoxAdapter(
            child: GuestNotice(message: context.l10n.matchGuestCannotLog),
          ),
        if (isRegistered && !hasPlayers)
          SliverToBoxAdapter(child: _needsPlayersHint(context)),
        _matchesSection(
          context,
          state,
          competitionId: competitionId,
          isRegistered: isRegistered,
          hasPlayers: hasPlayers,
          myPlayerId: myPlayerId,
        ),
        if (state.hasMore)
          SliverToBoxAdapter(child: _loadMoreButton(context, state, cubit)),
        if (state.actionFailure != null)
          SliverToBoxAdapter(child: _actionFailureText(context, state)),
      ],
    );
  }

  Widget _needsPlayersHint(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.lg),
      child: Text(context.l10n.matchNeedsPlayers, style: AppTypography.caption),
    );
  }

  Widget _matchesSection(
    BuildContext context,
    MatchListReady state, {
    required String competitionId,
    required bool isRegistered,
    required bool hasPlayers,
    required String? myPlayerId,
  }) {
    if (state.busy) return _loader();

    if (state.matches.isEmpty) {
      return SliverToBoxAdapter(
        child: _emptyState(
          context,
          state,
          isRegistered: isRegistered,
          hasPlayers: hasPlayers,
        ),
      );
    }

    return SliverMainAxisGroup(
      slivers: [
        for (final group in groupByDay(state.matches))
          _daySliver(
            context,
            group,
            competitionId: competitionId,
            myPlayerId: myPlayerId,
          ),
      ],
    );
  }

  Widget _daySliver(
    BuildContext context,
    MatchDayGroup group, {
    required String competitionId,
    required String? myPlayerId,
  }) {
    return SliverMainAxisGroup(
      slivers: [
        PinnedHeaderSliver(child: DayHeader(day: group.day)),
        SliverList.list(
          children: [
            for (final match in group.matches)
              _matchCard(
                context,
                match,
                competitionId: competitionId,
                myPlayerId: myPlayerId,
              ),
          ],
        ),
      ],
    );
  }

  Widget _matchCard(
    BuildContext context,
    MatchEntry match, {
    required String competitionId,
    required String? myPlayerId,
  }) {
    return MatchCard(
      match: match,
      myPlayerId: myPlayerId,
      onTap: () => showMatchDetailSheet(
        context,
        competitionId: competitionId,
        matchId: match.id,
        myPlayerId: myPlayerId,
      ),
    );
  }

  Widget _emptyState(
    BuildContext context,
    MatchListReady state, {
    required bool isRegistered,
    required bool hasPlayers,
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
        if (isRegistered) _newMatchHint(context),
      ],
    );
  }

  Widget _newMatchHint(BuildContext context) {
    return AppPlatform.useWideWeb(context)
        ? _sidebarHint(context)
        : _tabBarHint(context);
  }

  Widget _tabBarHint(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.xxl),
        Text(
          context.l10n.matchesCreateHintTabBar,
          style: AppTypography.caption,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        CurvedArrow(
          direction: CurvedArrowDirection.down,
          color: AdaptiveColors.accent(context),
          size: const Size(150, 300),
        ),
      ],
    );
  }

  Widget _sidebarHint(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CurvedArrow(
          direction: CurvedArrowDirection.left,
          color: AdaptiveColors.accent(context),
          size: const Size(150, 50),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            context.l10n.matchesCreateHintSidebar,
            style: AppTypography.caption,
          ),
        ),
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

  Widget _loader() {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: AdaptiveLoader(),
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
