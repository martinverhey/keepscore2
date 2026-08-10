import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/error/failure_messages.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/rating_delta.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../competition/domain/competition.dart';
import '../../domain/season.dart';
import '../../domain/standing.dart';
import '../bloc/leaderboard_cubit.dart';
import 'season_label.dart';

class LeaderboardView extends StatelessWidget {
  const LeaderboardView({
    super.key,
    required this.seasonLength,
    required this.myPlayerId,
  });

  final SeasonLength seasonLength;
  final String? myPlayerId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<LeaderboardCubit>();

    return BlocBuilder<LeaderboardCubit, LeaderboardState>(
      builder: (context, state) {
        if (state.status == LeaderboardStatus.loading) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: AdaptiveLoader(),
          );
        }

        if (state.status == LeaderboardStatus.failed && state.standings.isEmpty) {
          return ErrorRetry(
            message: state.failure!.localized(l10n),
            retryLabel: l10n.commonRetry,
            onRetry: cubit.load,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.selectedSeason != null)
              _SeasonBar(
                state: state,
                seasonLength: seasonLength,
                onPick: () => _pickSeason(context, state),
              ),
            const SizedBox(height: AppSpacing.md),

            if (state.busy)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: AdaptiveLoader(),
              )
            else if (state.standings.isEmpty)
              EmptyState(
                // An unplayed season has no rows at all; a played one lists
                // every active player, so an empty table means an empty roster.
                message: state.selectedSeason?.hasStarted ?? false
                    ? l10n.leaderboardNoPlayers
                    : l10n.leaderboardEmpty,
              )
            else ...[
              const _ColumnHeader(),
              for (final standing in state.standings)
                _StandingRow(
                  standing: standing,
                  isMe: standing.playerId == myPlayerId,
                ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _pickSeason(BuildContext context, LeaderboardState state) async {
    final cubit = context.read<LeaderboardCubit>();

    final startsAt = await showAdaptiveSheet<DateTime>(
      context,
      builder: (_) => _SeasonSheet(state: state, seasonLength: seasonLength),
    );
    if (startsAt != null) await cubit.selectSeason(startsAt);
  }
}

class _SeasonBar extends StatelessWidget {
  const _SeasonBar({
    required this.state,
    required this.seasonLength,
    required this.onPick,
  });

  final LeaderboardState state;
  final SeasonLength seasonLength;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final season = state.selectedSeason!;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                seasonLabel(context, season, seasonLength),
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              if (state.isShowingCurrentSeason) ...[
                const SizedBox(height: 2),
                Text(
                  l10n.leaderboardSeasonEnds(
                    DateFormat.MMMd(locale).format(season.endsAt),
                  ),
                  style: const TextStyle(color: AppColors.neutral, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
        if (state.hasHistory)
          AdaptiveButton(
            label: l10n.leaderboardPickSeason,
            kind: AdaptiveButtonKind.plain,
            expand: false,
            onPressed: onPick,
          ),
      ],
    );
  }
}

class _ColumnHeader extends StatelessWidget {
  const _ColumnHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const style = TextStyle(
      color: AppColors.neutral,
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.6,
    );

    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: AppSpacing.sm,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(l10n.leaderboardRank.toUpperCase(), style: style),
          ),
          Expanded(
            child: Text(l10n.leaderboardPlayer.toUpperCase(), style: style),
          ),
          Text(l10n.leaderboardRating.toUpperCase(), style: style),
        ],
      ),
    );
  }
}

class _StandingRow extends StatelessWidget {
  const _StandingRow({required this.standing, required this.isMe});

  final Standing standing;
  final bool isMe;

  Color? get _rankColor => switch (standing.rank) {
    1 => AppColors.gold,
    2 => AppColors.silver,
    3 => AppColors.bronze,
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final badges = [
      if (isMe) l10n.playersYou,
      if (!standing.isClaimed) l10n.playersUnclaimed,
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          borderRadius: AppRadius.card,
          color: isMe
              ? AdaptiveColors.accent(context).withValues(alpha: 0.12)
              : AppColors.neutral.withValues(alpha: 0.08),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                '${standing.rank}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _rankColor ?? AppColors.neutral,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    standing.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    standing.played == 0
                        ? l10n.leaderboardUnplayed
                        : [
                            l10n.leaderboardRecord(
                              standing.wins,
                              standing.losses,
                              standing.draws,
                            ),
                            ...badges,
                          ].join(' · '),
                    style: const TextStyle(
                      color: AppColors.neutral,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              formatRating(standing.rating),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeasonSheet extends StatelessWidget {
  const _SeasonSheet({required this.state, required this.seasonLength});

  final LeaderboardState state;
  final SeasonLength seasonLength;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.leaderboardPickSeason,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final season in state.seasons)
            AdaptiveButton(
              label: _label(context, season),
              kind: season == state.selectedSeason
                  ? AdaptiveButtonKind.tinted
                  : AdaptiveButtonKind.plain,
              onPressed: () => Navigator.of(context).pop(season.startsAt),
            ),
          const SizedBox(height: AppSpacing.sm),
          AdaptiveButton(
            label: l10n.commonCancel,
            kind: AdaptiveButtonKind.plain,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  String _label(BuildContext context, Season season) {
    final label = seasonLabel(context, season, seasonLength);
    return season == state.currentSeason
        ? '$label · ${AppLocalizations.of(context).leaderboardCurrentSeason}'
        : label;
  }
}
