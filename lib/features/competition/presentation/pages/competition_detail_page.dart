import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/data/recent_competition_store.dart';
import '../../../../core/error/failure_messages.dart';
import '../../../../core/extensions/build_context_l10n.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/tag.dart';
import '../../../auth/presentation/cubit/auth_bloc.dart';
import '../../../leaderboard/domain/leaderboard.dart';
import '../../../leaderboard/domain/medal_tally.dart';
import '../../../leaderboard/presentation/cubit/leaderboard_cubit.dart';
import '../../../leaderboard/presentation/widgets/game_type_filter_dropdown.dart';
import '../../../leaderboard/presentation/widgets/Leaderboard.page.dart';
import '../../../match/presentation/cubit/game_type_filter_cubit.dart';
import '../../../match/presentation/cubit/match_list_cubit.dart';
import '../../../match/presentation/widgets/matches_page.dart';
import '../../../player/presentation/cubit/players_cubit.dart';
import '../../../profile/presentation/widgets/profile_section.dart';
import '../../domain/competition.dart';
import '../cubit/competition_detail_cubit.dart';
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
    context.read<CompetitionDetailCubit>().load();
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
    final standings = leaderboardState.standings;

    return BlocConsumer<CompetitionDetailCubit, CompetitionDetailState>(
      listener: (context, state) {
        if (state.status == CompetitionDetailStatus.missing) {
          RecentCompetitionStore.clear();
          context.go(Routes.home);
        }
      },
      builder: (context, state) {
        final competition = state.competition;
        final isRegistered = session.canWrite;
        final isOwner = competition?.isOwnedBy(session.user?.id) ?? false;
        final hasPlayers = roster.active.length >= 2;
        final myPlayerId = state.myPlayerId;

        String? myDisplayName;
        for (final player in roster.players) {
          if (player.id == myPlayerId) {
            myDisplayName = player.displayName;
            break;
          }
        }

        Leaderboard? myStanding;
        for (final standing in standings) {
          if (standing.playerId == myPlayerId) {
            myStanding = standing;
            break;
          }
        }
        final myMedals = leaderboardState.medals[myPlayerId];

        return AdaptiveScaffold(
          title: switch (_tab) {
            CompetitionTab.leaderboard => context.l10n.leaderboardTitle,
            CompetitionTab.matches => context.l10n.matchesTitle,
          },
          onRefresh: _refresh,
          hasScrollBody: true,
          trailing: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GameTypeFilterDropdown(
                  selected: context.watch<GameTypeFilterCubit>().state,
                  onSelected: context.read<GameTypeFilterCubit>().select,
                ),
                const SizedBox(width: AppSpacing.xs),
                AdaptiveIconButton(
                  glyph: AdaptiveGlyph.settings,
                  onPressed: _openSettings,
                ),
              ],
            ),
          ),
          bottomBar: AdaptiveBottomTabBar(
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
          ),
          body: switch (state.status) {
            CompetitionDetailStatus.loading => const AdaptiveLoader(),
            CompetitionDetailStatus.missing => EmptyState(
              message: context.l10n.competitionNotFound,
            ),
            CompetitionDetailStatus.failed when competition == null =>
              ErrorRetry(
                message: state.failure!.localized(context.l10n),
                retryLabel: context.l10n.commonRetry,
                onRetry: context.read<CompetitionDetailCubit>().load,
              ),
            _ when competition == null => const SizedBox.shrink(),
            _ => _body(
              context,
              competition,
              isRegistered: isRegistered,
              isOwner: isOwner,
              hasPlayers: hasPlayers,
              myPlayerId: myPlayerId,
              myDisplayName: myDisplayName,
              myStanding: myStanding,
              myMedals: myMedals,
              playerCount: standings.length,
            ),
          },
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
    required Leaderboard? myStanding,
    required MedalTally? myMedals,
    required int playerCount,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xl,
            ),
            child: switch (_tab) {
              CompetitionTab.leaderboard => _leaderboardTab(
                context,
                competition,
                isOwner: isOwner,
                myPlayerId: myPlayerId,
                myDisplayName: myDisplayName,
                myStanding: myStanding,
                myMedals: myMedals,
                playerCount: playerCount,
              ),
              CompetitionTab.matches => MatchesPage(
                isRegistered: isRegistered,
                hasPlayers: hasPlayers,
                isOwner: isOwner,
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
    required Leaderboard? myStanding,
    required MedalTally? myMedals,
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
            standing: myStanding,
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
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _openSettings,
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
