import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure_messages.dart';
import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/extensions/date_time.extension.dart';
import '../../../../core/extensions/game_type.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/curved_arrow.dart';
import '../../../../core/widgets/curved_arrow_direction.enum.dart';
import '../../../../core/widgets/list_header.dart';
import '../../../../core/widgets/page_title.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/cubit/auth_bloc.dart';
import '../../../auth/presentation/widgets/guest_notice.dart';
import '../../../competition/presentation/cubit/competition_cubit.dart';
import '../../../player/presentation/cubit/players_cubit.dart';
import '../../domain/game_type.enum.dart';
import '../../domain/match_entry.model.dart';
import '../cubit/game_type_filter_cubit.dart';
import '../cubit/match_list_cubit.dart';
import 'day_header.dart';
import 'game_type_filter_button.dart';
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
  final ValueNotifier<DateTime?> _currentDay = ValueNotifier(null);
  final Map<DateTime, double> _dayHeaderStarts = {};
  List<DateTime> _days = const [];
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    context.read<MatchListCubit>().load();
  }

  @override
  void dispose() {
    _currentDay.dispose();
    super.dispose();
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

    return NotificationListener<ScrollNotification>(
      onNotification: _trackDay,
      child: AdaptiveScaffold(
        title: context.l10n.matchesTitle,
        subtitle: _daySubtitle(),
        onRefresh: _refresh,
        trailing: _gameTypeFilterButton(context),
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
      ),
    );
  }

  bool _trackDay(ScrollNotification notification) {
    if (notification.depth > 0) return false;
    _scrollOffset = notification.metrics.pixels;
    _resolveDay();
    return false;
  }

  void _rememberDays(List<DateTime> days) {
    _days = days;
    _scheduleDayResolve();
  }

  void _scheduleDayResolve() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _resolveDay();
    });
  }

  void _resolveDay() {
    _currentDay.value = _dayAtCaptionLine();
  }

  DateTime? _dayAtCaptionLine() {
    final captionLine =
        _scrollOffset +
        MediaQuery.paddingOf(context).top +
        AdaptiveTopBar.subtitleTop -
        DayHeader.textInset;

    DateTime? handedOver;
    for (final day in _days) {
      final start = _dayHeaderStarts[day];
      if (start == null || start > captionLine) break;
      handedOver = day;
    }
    return handedOver;
  }

  Widget _daySubtitle() {
    return ValueListenableBuilder<DateTime?>(
      valueListenable: _currentDay,
      builder: (context, day, _) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        layoutBuilder: _startAlignedStack,
        child: day == null
            ? const SizedBox.shrink()
            : Text(
                day.matchDayLabel(context),
                key: ValueKey(day),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.captionStrong,
              ),
      ),
    );
  }

  Widget _gameTypeFilterButton(BuildContext context) {
    return BlocBuilder<MatchListCubit, MatchListState>(
      builder: (context, state) => GameTypeFilterButton(
        selected: context.watch<GameTypeFilterCubit>().state,
        played: state.seasonGameTypes,
        onSelected: context.read<GameTypeFilterCubit>().select,
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
        if (!isRegistered) SliverToBoxAdapter(child: _guestNotice(context)),
        if (isRegistered && !hasPlayers)
          SliverToBoxAdapter(child: _needsPlayersHint(context)),
        if (state.selectedGameType case final gameType?)
          SliverToBoxAdapter(child: _gameTypeHeader(context, gameType)),
        _matchesSection(
          context,
          state,
          competitionId: competitionId,
          isRegistered: isRegistered,
          myPlayerId: myPlayerId,
        ),
        if (state.hasMore)
          SliverToBoxAdapter(child: _loadMoreButton(context, state, cubit)),
        if (state.actionFailure != null)
          SliverToBoxAdapter(child: _actionFailureText(context, state)),
      ],
    );
  }

  Widget _guestNotice(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GuestNotice(message: context.l10n.matchGuestCannotLog),
    );
  }

  Widget _needsPlayersHint(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.lg),
      child: Text(context.l10n.matchNeedsPlayers, style: AppTypography.caption),
    );
  }

  Widget _gameTypeHeader(BuildContext context, GameType gameType) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListHeader(title: gameType.label(context)),
    );
  }

  Widget _matchesSection(
    BuildContext context,
    MatchListReady state, {
    required String competitionId,
    required bool isRegistered,
    required String? myPlayerId,
  }) {
    if (state.busy) return _loader();

    if (state.matches.isEmpty) {
      _rememberDays(const []);
      return SliverToBoxAdapter(
        child: _emptyState(context, isRegistered: isRegistered),
      );
    }

    final groups = groupByDay(state.matches);
    _rememberDays([for (final group in groups) group.day]);

    return SliverMainAxisGroup(
      slivers: [
        for (final group in groups)
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
        ..._dayHeaderSlivers(context, group.day),
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

  List<Widget> _dayHeaderSlivers(BuildContext context, DateTime day) {
    if (!AdaptiveGlass.isEnabled(context)) {
      return [PinnedHeaderSliver(child: DayHeader(day: day))];
    }

    return [
      _dayHeaderMarker(day),
      SliverToBoxAdapter(child: DayHeader(day: day)),
    ];
  }

  Widget _dayHeaderMarker(DateTime day) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        _dayHeaderStarts[day] = constraints.precedingScrollExtent;
        return const SliverToBoxAdapter(child: SizedBox.shrink());
      },
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

  Widget _emptyState(BuildContext context, {required bool isRegistered}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EmptyState(message: context.l10n.matchesEmpty),
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

Widget _startAlignedStack(Widget? current, List<Widget> previous) {
  return Stack(
    alignment: AlignmentDirectional.centerStart,
    children: [...previous, ?current],
  );
}
