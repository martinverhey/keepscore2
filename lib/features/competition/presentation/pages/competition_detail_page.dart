import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/data/recent_competition_store.dart';
import '../../../../core/error/failure_messages.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/cubit/auth_bloc.dart';
import '../../../leaderboard/presentation/cubit/leaderboard_cubit.dart';
import '../../../leaderboard/presentation/widgets/leaderboard_view.dart';
import '../../../match/presentation/cubit/match_list_cubit.dart';
import '../../../match/presentation/widgets/match_list_view.dart';
import '../../../player/presentation/cubit/players_cubit.dart';
import '../../../profile/presentation/widgets/profile_avatar_button.dart';
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
    context.read<MatchListCubit>().refresh(),
    context.read<LeaderboardCubit>().refresh(),
  ]);

  void _openSettingsThenCompetitions() {
    context.push(Routes.competitionMenu(widget.competitionId));
    context.push(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = context.watch<AuthBloc>().state;
    final roster = context.watch<PlayersCubit>().state;

    return BlocBuilder<CompetitionDetailCubit, CompetitionDetailState>(
      builder: (context, state) {
        final competition = state.competition;
        final isRegistered = session.canWrite;
        final hasPlayers = roster.active.length >= 2;
        final myPlayerId = state.myPlayerId;

        String? myDisplayName;
        for (final player in roster.players) {
          if (player.id == myPlayerId) {
            myDisplayName = player.displayName;
            break;
          }
        }

        return AdaptiveScaffold(
          title: switch (_tab) {
            CompetitionTab.leaderboard => l10n.leaderboardTitle,
            CompetitionTab.matches => l10n.matchesTitle,
          },
          onRefresh: _refresh,
          trailing: AdaptiveIconButton(
            glyph: AdaptiveGlyph.settings,
            onPressed: () =>
                context.push(Routes.competitionMenu(widget.competitionId)),
          ),
          bottomBar: AdaptiveBottomTabBar(
            items: [
              AdaptiveTabBarItem(
                glyph: AdaptiveGlyph.leaderboard,
                label: l10n.leaderboardTitle,
              ),
              if (isRegistered)
                AdaptiveTabBarItem(
                  glyph: AdaptiveGlyph.newMatch,
                  label: l10n.matchNew,
                ),
              AdaptiveTabBarItem(
                glyph: AdaptiveGlyph.matches,
                label: l10n.matchesTitle,
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
              message: l10n.competitionNotFound,
            ),
            CompetitionDetailStatus.failed when competition == null =>
              ErrorRetry(
                message: state.failure!.localized(l10n),
                retryLabel: l10n.commonRetry,
                onRetry: context.read<CompetitionDetailCubit>().load,
              ),
            _ => Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.xl,
              ),
              child: switch (_tab) {
                CompetitionTab.leaderboard => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _openSettingsThenCompetitions,
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              competition!.name,
                              style: const TextStyle(
                                color: AppColors.neutral,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const AdaptiveIcon(
                            AdaptiveGlyph.chevronRight,
                            color: AppColors.neutral,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (myPlayerId != null && myDisplayName != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ProfileAvatarButton(
                          competitionId: widget.competitionId,
                          playerId: myPlayerId,
                          displayName: myDisplayName,
                        ),
                      ),
                    const SizedBox(height: AppSpacing.lg),
                    Align(
                      alignment: Alignment.centerRight,
                      child: AdaptiveButton(
                        label: l10n.competitionInviteAction,
                        icon: AdaptiveIcon(
                          AdaptiveGlyph.invite,
                          size: 18,
                          color: AdaptiveColors.accent(context),
                        ),
                        kind: AdaptiveButtonKind.plain,
                        expand: false,
                        onPressed: () => showInviteSheet(
                          context,
                          code: competition.joinCode,
                        ),
                      ),
                    ),
                    LeaderboardView(
                      competitionId: widget.competitionId,
                      seasonLength: competition.seasonLength,
                      myPlayerId: myPlayerId,
                      onGoToMatches: () =>
                          setState(() => _tab = CompetitionTab.matches),
                    ),
                  ],
                ),
                CompetitionTab.matches => MatchListView(
                  isRegistered: isRegistered,
                  hasPlayers: hasPlayers,
                  onOpenMatch: (matchId) => _openAndReload(
                    Routes.match(widget.competitionId, matchId),
                  ),
                ),
              },
            ),
          },
        );
      },
    );
  }
}
