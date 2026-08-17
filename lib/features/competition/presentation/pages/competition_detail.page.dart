import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/data/recent_competition_store.dart';
import '../../../../core/error/failure_messages.dart';
import '../../../../core/extensions/box_constraints_content_inset.dart';
import '../../../../core/extensions/build_context_l10n.dart';
import '../../../../core/extensions/competition_ownership.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/page_title.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/tag.dart';
import '../../../auth/presentation/cubit/auth_bloc.dart';
import '../../../leaderboard/domain/leaderboard.model.dart';
import '../../../leaderboard/domain/medals.model.dart';
import '../../../leaderboard/presentation/cubit/leaderboard_cubit.dart';
import '../../../leaderboard/presentation/widgets/game_type_filter_dropdown.dart';
import '../../../leaderboard/presentation/widgets/leaderboard.page.dart';
import '../../../match/presentation/cubit/game_type_filter_cubit.dart';
import '../../../match/presentation/cubit/match_list_cubit.dart';
import '../../../match/presentation/widgets/matches.page.dart';
import '../../../player/presentation/cubit/players_cubit.dart';
import '../../../profile/presentation/widgets/profile_section.dart';
import '../../domain/competition.model.dart';
import '../cubit/competition_detail_cubit.dart';
import '../widgets/competition_section.enum.dart';
import '../widgets/open_home.dart';
import '../widgets/sidebar.dart';
import '../widgets/invite_sheet.dart';

enum CompetitionTab { leaderboard, matches }

class CompetitionDetailPage extends StatefulWidget {
  const CompetitionDetailPage({super.key, required this.competitionId});
  final String competitionId;

  @override
  State<CompetitionDetailPage> createState() => _CompetitionDetailPageState();
}

class _CompetitionDetailPageState extends State<CompetitionDetailPage> {
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
    context.read<CompetitionDetailCubit>().refresh(),
    context.read<PlayersCubit>().refresh(),
    context.read<MatchListCubit>().refresh(),
    context.read<LeaderboardCubit>().refresh(),
  ]);

  Future<void> _openAndReload(String route) async {
    await context.push<bool>(route);
    if (!mounted) return;
    await _reload();
  }

  Future<void> _openNewMatch() async {
    final saved = await context.push<bool>(
      Routes.newMatch(widget.competitionId),
    );
    if (!mounted) return;
    if (saved ?? false) setState(() => _tab = CompetitionTab.matches);
    await _reload();
  }

  Future<void> _reload() => Future.wait([
    context.read<CompetitionDetailCubit>().refresh(),
    context.read<PlayersCubit>().refresh(),
    context.read<MatchListCubit>().refresh(),
    context.read<LeaderboardCubit>().refresh(),
  ]);

  Future<void> _openSettings() =>
      _openAndReload(Routes.competitionMenu(widget.competitionId));

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthBloc>().state;
    final roster = context.watch<PlayersCubit>().state;
    final leaderboardState = context.watch<LeaderboardCubit>().state;
    final leaderboards = leaderboardState is LeaderboardReady
        ? leaderboardState.leaderboards
        : const [];

    return BlocConsumer<CompetitionDetailCubit, CompetitionDetailState>(
      listener: (context, state) {
        if (state is CompetitionDetailMissing) {
          RecentCompetitionStore.clear();
          context.go(Routes.home);
        }
      },
      builder: (context, state) {
        final competition = state.competition;
        final isRegistered = session.canWrite;
        final isOwner = competition.isOwnedBySession(session);
        final hasPlayers = roster is PlayersReady && roster.active.length >= 2;
        final myPlayerId = state.myPlayerId;

        final rosterPlayers = roster is PlayersReady
            ? roster.players
            : const [];
        String? myDisplayName;
        for (final player in rosterPlayers) {
          if (player.id == myPlayerId) {
            myDisplayName = player.displayName;
            break;
          }
        }

        Leaderboard? myLeaderboard;
        for (final leaderboard in leaderboards) {
          if (leaderboard.playerId == myPlayerId) {
            myLeaderboard = leaderboard;
            break;
          }
        }
        final myMedals = leaderboardState is LeaderboardReady
            ? leaderboardState.medals[myPlayerId]
            : null;
        final tabTitle = switch (_tab) {
          CompetitionTab.leaderboard => context.l10n.leaderboardTitle,
          CompetitionTab.matches => context.l10n.matchesTitle,
        };
        setPageTitle(
          context,
          competition == null ? tabTitle : '${competition.name} · $tabTitle',
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
          onOpenHome: () => openHome(
            context,
            replace: false,
            competitionId: widget.competitionId,
            competitionName: competition?.name,
            canManageSettings: session.canWrite && isOwner,
          ),
          onOpenTheme: () => context.push(Routes.theme),
          onSignOut: () =>
              context.read<AuthBloc>().add(const AuthSignOutRequested()),
          child: AdaptiveScaffold(
            title: tabTitle,
            onRefresh: _refresh,
            hasScrollBody: true,
            trailing: _trailingRow(context),
            bottomBar: AppPlatform.useWideWeb(context)
                ? null
                : _bottomTabBar(context, isRegistered: isRegistered),
            body: switch (state) {
              CompetitionDetailLoading() => const AdaptiveLoader(),
              CompetitionDetailMissing() => EmptyState(
                message: context.l10n.competitionNotFound,
              ),
              CompetitionDetailFailed(:final failure) => ErrorRetry(
                message: failure.localized(context.l10n),
                retryLabel: context.l10n.commonRetry,
                onRetry: context.read<CompetitionDetailCubit>().load,
              ),
              CompetitionDetailReady(:final competition) => _body(
                context,
                competition,
                isRegistered: isRegistered,
                isOwner: isOwner,
                hasPlayers: hasPlayers,
                myPlayerId: myPlayerId,
                myDisplayName: myDisplayName,
                myLeaderboard: myLeaderboard,
                myMedals: myMedals,
                playerCount: leaderboards.length,
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
      case CompetitionSection.settings:
        _openAndReload(Routes.competitionSettings(widget.competitionId));
      case CompetitionSection.competitions:
        {
          final competition = context
              .read<CompetitionDetailCubit>()
              .state
              .competition;
          final session = context.read<AuthBloc>().state;
          openHome(
            context,
            replace: false,
            competitionId: widget.competitionId,
            competitionName: competition?.name,
            canManageSettings:
                session.canWrite &&
                (competition?.isOwnedBy(session.user?.id) ?? false),
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
    required Leaderboard? myLeaderboard,
    required Medals? myMedals,
    required int playerCount,
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
              CompetitionTab.leaderboard => _leaderboardTab(
                context,
                competition,
                isOwner: isOwner,
                myPlayerId: myPlayerId,
                myDisplayName: myDisplayName,
                myLeaderboard: myLeaderboard,
                myMedals: myMedals,
                playerCount: playerCount,
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

  Widget _leaderboardTab(
    BuildContext context,
    Competition competition, {
    required bool isOwner,
    required String? myPlayerId,
    required String? myDisplayName,
    required Leaderboard? myLeaderboard,
    required Medals? myMedals,
    required int playerCount,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _competitionHeader(context, competition),
        const SizedBox(height: AppSpacing.sm),
        if (myPlayerId != null && myDisplayName != null)
          ProfileSection(
            competitionId: widget.competitionId,
            playerId: myPlayerId,
            displayName: myDisplayName,
            seasonLength: competition.seasonLength,
            leaderboard: myLeaderboard,
            medals: myMedals,
            playerCount: playerCount,
          ),
        const SizedBox(height: AppSpacing.lg),
        LeaderboardPage(
          competitionId: widget.competitionId,
          seasonLength: competition.seasonLength,
          myPlayerId: myPlayerId,
          isOwner: isOwner,
          onManagePlayers: () =>
              _openAndReload(Routes.players(widget.competitionId)),
        ),
      ],
    );
  }

  Widget _competitionHeader(BuildContext context, Competition competition) {
    return Row(
      children: [
        Expanded(
          child: AdaptiveTappable(
            onTap: () => context.push(Routes.home),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    competition.name,
                    style: const TextStyle(
                      color: AppColors.neutral,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                const AdaptiveIcon(
                  AdaptiveGlyph.chevronRight,
                  color: AppColors.neutral,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _inviteButton(context, competition.joinCode),
        const SizedBox(width: AppSpacing.xs),
        Tag(
          competition.joinCode,
          color: AdaptiveColors.accent(context),
          style: TagStyle.code,
        ),
      ],
    );
  }

  Widget _inviteButton(BuildContext context, String joinCode) {
    return AdaptiveIconButton(
      glyph: AdaptiveGlyph.invite,
      semanticLabel: context.l10n.competitionInviteAction,
      onPressed: () => showInviteSheet(context, code: joinCode),
    );
  }
}
