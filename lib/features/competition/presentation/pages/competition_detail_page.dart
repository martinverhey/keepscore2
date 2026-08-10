import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/error/failure_messages.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../leaderboard/presentation/bloc/leaderboard_cubit.dart';
import '../../../leaderboard/presentation/widgets/leaderboard_view.dart';
import '../../../match/presentation/bloc/match_list_cubit.dart';
import '../../../match/presentation/widgets/match_list_view.dart';
import '../../../player/presentation/bloc/players_cubit.dart';
import '../../../player/presentation/widgets/player_roster.dart';
import '../bloc/competition_detail_cubit.dart';

enum CompetitionTab { leaderboard, matches, players }

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
        final isOwner = competition?.isOwnedBy(session.user?.id) ?? false;

        return AdaptiveScaffold(
          title: competition?.name ?? l10n.commonLoading,
          trailing: isOwner && session.canWrite
              ? AdaptiveButton(
                  label: l10n.competitionSettings,
                  kind: AdaptiveButtonKind.plain,
                  expand: false,
                  onPressed: () => context.push(
                    Routes.competitionSettings(widget.competitionId),
                  ),
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
            _ => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    child: AdaptiveSegmented<CompetitionTab>(
                      value: _tab,
                      segments: {
                        CompetitionTab.leaderboard: l10n.leaderboardTitle,
                        CompetitionTab.matches: l10n.matchesTitle,
                        CompetitionTab.players: l10n.playersTitle,
                      },
                      onChanged: (tab) => setState(() => _tab = tab),
                    ),
                  ),
                  Expanded(
                    child: AdaptiveRefresh(
                      onRefresh: _refresh,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.sm,
                          AppSpacing.md,
                          AppSpacing.xl,
                        ),
                        child: switch (_tab) {
                          CompetitionTab.leaderboard => LeaderboardView(
                              seasonLength: competition!.seasonLength,
                              myPlayerId: state.myPlayerId,
                            ),
                          CompetitionTab.matches => MatchListView(
                              canLog: session.canWrite,
                              hasPlayers: roster.active.length >= 2,
                              onNewMatch: () => _openAndReload(
                                Routes.newMatch(widget.competitionId),
                              ),
                              onOpenMatch: (matchId) => _openAndReload(
                                Routes.match(widget.competitionId, matchId),
                              ),
                            ),
                          CompetitionTab.players => Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _JoinCodeCard(code: competition!.joinCode),
                                const SizedBox(height: AppSpacing.lg),
                                PlayerRoster(
                                  ownerUserId: competition.ownerId,
                                  myUserId: session.user?.id,
                                  isRegistered: session.canWrite,
                                ),
                              ],
                            ),
                        },
                      ),
                    ),
                  ),
                ],
              ),
          },
        );
      },
    );
  }
}

class _JoinCodeCard extends StatefulWidget {
  const _JoinCodeCard({required this.code});
  final String code;

  @override
  State<_JoinCodeCard> createState() => _JoinCodeCardState();
}

class _JoinCodeCardState extends State<_JoinCodeCard> {
  Timer? _resetCopied;
  bool _copied = false;

  @override
  void dispose() {
    _resetCopied?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (!mounted) return;
    setState(() => _copied = true);
    _resetCopied?.cancel();
    _resetCopied = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: AppRadius.card,
        color: AdaptiveColors.accent(context).withValues(alpha: 0.10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.code,
                  style: TextStyle(
                    fontFeatures: const [FontFeature.tabularFigures()],
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                    color: AdaptiveColors.accent(context),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.competitionCodeHelp,
                  style: const TextStyle(
                    color: AppColors.neutral,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          AdaptiveButton(
            label: _copied ? l10n.competitionCodeCopied : l10n.commonCopy,
            kind: AdaptiveButtonKind.plain,
            expand: false,
            onPressed: _copy,
          ),
        ],
      ),
    );
  }
}
