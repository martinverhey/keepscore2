import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/data/recent_competition_store.dart';
import '../../../../core/error/failure_messages.dart';
import '../../../../core/extensions/box_constraints.extension.dart';
import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/extensions/competition.extension.dart';
import '../../../../core/extensions/player_list.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/page_title.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/cubit/auth_bloc.dart';
import '../../../leaderboard/presentation/cubit/leaderboard_cubit.dart';
import '../../../leaderboard/presentation/widgets/leaderboard.page.dart';
import '../../../match/presentation/cubit/game_type_filter_cubit.dart';
import '../../../match/presentation/cubit/match_list_cubit.dart';
import '../../../match/presentation/widgets/game_type_filter_dropdown.dart';
import '../../../match/presentation/widgets/matches.page.dart';
import '../../../player/domain/player.model.dart';
import '../../../player/presentation/cubit/players_cubit.dart';
import '../../domain/competition.model.dart';
import '../cubit/competition_cubit.dart';
import '../widgets/competition_section.enum.dart';
import '../widgets/home_sidebar_competition.dart';
import '../widgets/open_home.dart';
import '../widgets/open_theme.dart';
import '../widgets/sidebar.dart';

enum CompetitionTab { leaderboard, matches }

extension CompetitionTabTitle on CompetitionTab {
  String title(BuildContext context) => switch (this) {
    CompetitionTab.leaderboard => context.l10n.leaderboardTitle,
    CompetitionTab.matches => context.l10n.matchesTitle,
  };
}

class CompetitionContent extends StatefulWidget {
  const CompetitionContent({super.key, required this.competitionId});
  final String competitionId;

  @override
  State<CompetitionContent> createState() => _CompetitionContentState();
}

class _CompetitionContentState extends State<CompetitionContent> {
  CompetitionTab _tab = CompetitionTab.leaderboard;

  @override
  void initState() {
    super.initState();
    context.read<PlayersCubit>().load();
    context.read<MatchListCubit>().load();
    context.read<LeaderboardCubit>().load();
    RecentCompetitionStore.set(widget.competitionId);
  }

  Future<void> _refresh() => Future.wait([
    context.read<CompetitionCubit>().refresh(),
    context.read<PlayersCubit>().refresh(),
    context.read<MatchListCubit>().refresh(),
    context.read<LeaderboardCubit>().refresh(),
  ]);

  Future<void> _openAndReload(String route) async {
    final section = await context.push<CompetitionSection>(route);
    if (!mounted) return;
    _applySection(section);
    await _reload();
  }

  void _applySection(CompetitionSection? section) {
    if (section == CompetitionSection.leaderboard) {
      setState(() => _tab = CompetitionTab.leaderboard);
    } else if (section == CompetitionSection.matches) {
      setState(() => _tab = CompetitionTab.matches);
    }
  }

  Future<void> _openNewMatch() async {
    final result = await context.push<Object?>(
      Routes.newMatch(widget.competitionId),
    );
    if (!mounted) return;
    if (result == true) {
      setState(() => _tab = CompetitionTab.matches);
    } else if (result is CompetitionSection) {
      _applySection(result);
    }
    await _reload();
  }

  Future<void> _reload() => Future.wait([
    context.read<CompetitionCubit>().refresh(),
    context.read<PlayersCubit>().refresh(),
    context.read<MatchListCubit>().refresh(),
    context.read<LeaderboardCubit>().refresh(),
  ]);

  Future<void> _openSettings() =>
      _openAndReload(Routes.settings(widget.competitionId));

  Future<void> _openTheme({
    required String? competitionName,
    required bool canManageSettings,
  }) async {
    final section = await openTheme(
      context,
      replace: false,
      sidebarCompetition: HomeSidebarCompetition(
        competitionId: widget.competitionId,
        competitionName: competitionName,
        canManageSettings: canManageSettings,
      ),
    );
    if (!mounted) return;
    _applySection(section);
  }

  Future<void> _openHome({
    required String? competitionName,
    required bool canManageSettings,
  }) async {
    final section = await openHome(
      context,
      replace: false,
      competitionId: widget.competitionId,
      competitionName: competitionName,
      canManageSettings: canManageSettings,
    );
    if (!mounted) return;
    _applySection(section);
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthBloc>().state;
    final playersState = context.watch<PlayersCubit>().state;

    return BlocConsumer<CompetitionCubit, CompetitionState>(
      listener: (context, state) {
        if (state is CompetitionMissing) {
          RecentCompetitionStore.clear();
          context.go(Routes.home);
        }
      },
      builder: (context, state) {
        final competition = state.competition;
        final isRegistered = session.canWrite;
        final isOwner = competition.isOwnedBySession(session);
        final hasPlayers =
            playersState is PlayersReady && playersState.active.length >= 2;
        final myPlayerId = state.myPlayerId;

        final List<Player> players = playersState is PlayersReady
            ? playersState.players
            : const [];

        setPageTitle(
          context,
          competition == null
              ? _tab.title(context)
              : '${competition.name} · ${_tab.title(context)}',
        );

        return Sidebar(
          competitionName: competition?.name,
          current: _tab == CompetitionTab.leaderboard
              ? CompetitionSection.leaderboard
              : CompetitionSection.matches,
          canManageSettings: session.canWrite && isOwner,
          isRegistered: isRegistered,
          onSelectSection: _selectSection,
          onNewMatch: _openNewMatch,
          onOpenHome: () => _openHome(
            competitionName: competition?.name,
            canManageSettings: session.canWrite && isOwner,
          ),
          onOpenTheme: () => _openTheme(
            competitionName: competition?.name,
            canManageSettings: session.canWrite && isOwner,
          ),
          onSignOut: () =>
              context.read<AuthBloc>().add(const AuthSignOutRequested()),
          child: AdaptiveScaffold(
            title: _tab.title(context),
            onRefresh: _refresh,
            hasScrollBody: true,
            trailing: _trailingRow(context),
            bottomBar: AppPlatform.useWideWeb(context)
                ? null
                : _bottomTabBar(context, isRegistered: isRegistered),
            body: switch (state) {
              CompetitionLoading() => const AdaptiveLoader(),
              CompetitionMissing() => EmptyState(
                message: context.l10n.competitionNotFound,
              ),
              CompetitionFailed(:final failure) => ErrorRetry(
                message: failure.localized(context.l10n),
                retryLabel: context.l10n.commonRetry,
                onRetry: context.read<CompetitionCubit>().load,
              ),
              CompetitionReady(:final competition) => _body(
                context,
                competition,
                isRegistered: isRegistered,
                isOwner: isOwner,
                hasPlayers: hasPlayers,
                myPlayerId: myPlayerId,
                myDisplayName: players.displayNameFor(myPlayerId),
              ),
            },
          ),
        );
      },
    );
  }

  void _selectSection(CompetitionSection section) {
    switch (section) {
      case CompetitionSection.leaderboard:
        setState(() => _tab = CompetitionTab.leaderboard);
      case CompetitionSection.matches:
        setState(() => _tab = CompetitionTab.matches);
      case CompetitionSection.players:
        _openAndReload(Routes.players(widget.competitionId));
      case CompetitionSection.history:
        _openAndReload(Routes.history(widget.competitionId));
      case CompetitionSection.configuration:
        _openAndReload(Routes.configuration(widget.competitionId));
      case CompetitionSection.competitions:
        {
          final competition = context
              .read<CompetitionCubit>()
              .state
              .competition;
          final session = context.read<AuthBloc>().state;
          _openHome(
            competitionName: competition?.name,
            canManageSettings:
                session.canWrite && competition.isOwnedBySession(session),
          );
        }
    }
  }

  Widget _trailingRow(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_tab == CompetitionTab.matches)
            GameTypeFilterDropdown(
              selected: context.watch<GameTypeFilterCubit>().state,
              onSelected: context.read<GameTypeFilterCubit>().select,
            ),
          if (!AppPlatform.useWideWeb(context)) ...[
            const SizedBox(width: AppSpacing.xs),
            AdaptiveIconButton(
              glyph: AdaptiveGlyph.settings,
              onPressed: _openSettings,
            ),
          ],
        ],
      ),
    );
  }

  Widget _bottomTabBar(BuildContext context, {required bool isRegistered}) {
    return AdaptiveBottomTabBar(
      items: [
        AdaptiveTabBarItem(
          glyph: AdaptiveGlyph.leaderboard,
          label: context.l10n.leaderboardTitle,
        ),
        if (isRegistered)
          AdaptiveTabBarItem(
            glyph: AdaptiveGlyph.newMatch,
            label: context.l10n.matchNew,
          ),
        AdaptiveTabBarItem(
          glyph: AdaptiveGlyph.matches,
          label: context.l10n.matchesTitle,
        ),
      ],
      selectedIndex: _tab == CompetitionTab.leaderboard
          ? 0
          : (isRegistered ? 2 : 1),
      onTap: (index) {
        if (isRegistered && index == 1) {
          _openNewMatch();
          return;
        }
        setState(
          () => _tab = index == 0
              ? CompetitionTab.leaderboard
              : CompetitionTab.matches,
        );
      },
    );
  }

  Widget _body(
    BuildContext context,
    Competition competition, {
    required bool isRegistered,
    required bool isOwner,
    required bool hasPlayers,
    required String? myPlayerId,
    required String? myDisplayName,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              constraints.contentHorizontalInset,
              AppSpacing.sm,
              constraints.contentHorizontalInset,
              AppSpacing.xl,
            ),
            child: switch (_tab) {
              CompetitionTab.leaderboard => LeaderboardPage(
                competitionId: widget.competitionId,
                competition: competition,
                isOwner: isOwner,
                myPlayerId: myPlayerId,
                myDisplayName: myDisplayName,
                onManagePlayers: () =>
                    _openAndReload(Routes.players(widget.competitionId)),
                onOpenCompetitions: () => _openHome(
                  competitionName: competition.name,
                  canManageSettings: isRegistered && isOwner,
                ),
              ),
              CompetitionTab.matches => MatchesPage(
                isRegistered: isRegistered,
                hasPlayers: hasPlayers,
                isOwner: isOwner,
                myPlayerId: myPlayerId,
                onOpenMatch: (matchId) =>
                    _openAndReload(Routes.match(widget.competitionId, matchId)),
                onCreateMatch: _openNewMatch,
              ),
            },
          ),
        ),
      ),
    );
  }
}
