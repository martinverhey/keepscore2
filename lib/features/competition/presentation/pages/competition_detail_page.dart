import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
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
  }

  Future<void> _refresh() => Future.wait([
        context.read<CompetitionDetailCubit>().refresh(),
        context.read<PlayersCubit>().refresh(),
        context.read<MatchListCubit>().refresh(),
        context.read<LeaderboardCubit>().refresh(),
      ]);

  // A match that was logged, edited or deleted moves both the ratings and the
  // match count, and the pushed page can be left either way. Realtime would
  // catch most of it, but not the counts on the overview.
  Future<void> _openAndReload(String route) async {
    await context.push<bool>(route);
    if (!mounted) return;
    await Future.wait([
      context.read<CompetitionDetailCubit>().refresh(),
      context.read<MatchListCubit>().refresh(),
      context.read<LeaderboardCubit>().refresh(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = context.watch<AuthBloc>().state;
    final roster = context.watch<PlayersCubit>().state;

    return BlocBuilder<CompetitionDetailCubit, CompetitionDetailState>(
      builder: (context, state) {
        final competition = state.competition;
        final canLog = session.canWrite;
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
          title: competition?.name ?? l10n.commonLoading,
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
              AdaptiveTabBarItem(
                glyph: AdaptiveGlyph.newMatch,
                label: l10n.matchNew,
              ),
              AdaptiveTabBarItem(
                glyph: AdaptiveGlyph.matches,
                label: l10n.matchesTitle,
              ),
            ],
            selectedIndex: _tab == CompetitionTab.leaderboard ? 0 : 2,
            onTap: (index) {
              if (index == 1) {
                _openAndReload(Routes.newMatch(widget.competitionId));
                return;
              }
              setState(
                () => _tab = index == 0
                    ? CompetitionTab.leaderboard
                    : CompetitionTab.matches,
              );
            },
          ),
          floatingAction: canLog && hasPlayers
              ? AdaptiveButton(
                  label: l10n.matchAddFab,
                  kind: AdaptiveButtonKind.filled,
                  expand: false,
                  onPressed: () =>
                      _openAndReload(Routes.newMatch(widget.competitionId)),
                )
              : null,
          body: switch (state.status) {
            CompetitionDetailStatus.loading => const AdaptiveLoader(),
            CompetitionDetailStatus.missing =>
              EmptyState(message: l10n.competitionNotFound),
            CompetitionDetailStatus.failed when competition == null =>
              ErrorRetry(
                message: state.failure!.localized(l10n),
                retryLabel: l10n.commonRetry,
                onRetry: context.read<CompetitionDetailCubit>().load,
              ),
            _ => AdaptiveRefresh(
                onRefresh: _refresh,
                child: Padding(
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
                          if (myPlayerId != null && myDisplayName != null) ...[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: ProfileAvatarButton(
                                competitionId: widget.competitionId,
                                playerId: myPlayerId,
                                displayName: myDisplayName,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                          LeaderboardView(
                            seasonLength: competition!.seasonLength,
                            myPlayerId: myPlayerId,
                          ),
                        ],
                      ),
                    CompetitionTab.matches => MatchListView(
                        canLog: canLog,
                        hasPlayers: hasPlayers,
                        onNewMatch: () => _openAndReload(
                          Routes.newMatch(widget.competitionId),
                        ),
                        onOpenMatch: (matchId) => _openAndReload(
                          Routes.match(widget.competitionId, matchId),
                        ),
                      ),
                  },
                ),
              ),
          },
        );
      },
    );
  }
}
