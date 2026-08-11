import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure_messages.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/rating_delta.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../cubit/profile_cubit.dart';
import 'initials_circle.dart';
import 'rating_trend_chart.dart';

class ProfileSheet extends StatelessWidget {
  const ProfileSheet({super.key, required this.displayName});
  final String displayName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<ProfileCubit>();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  InitialsCircle(displayName: displayName, size: 48),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              switch (state.status) {
                ProfileStatus.loading => const Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: AdaptiveLoader(),
                  ),
                ProfileStatus.failed => ErrorRetry(
                    message: state.failure!.localized(l10n),
                    retryLabel: l10n.commonRetry,
                    onRetry: cubit.load,
                  ),
                ProfileStatus.ready => _Ready(state: state),
              },
            ],
          );
        },
      ),
    );
  }
}

class _Ready extends StatelessWidget {
  const _Ready({required this.state});
  final ProfileState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final standing = state.standing;

    if (standing == null) {
      return EmptyState(message: l10n.profileNotEnoughMatches);
    }

    final winRate =
        standing.played == 0 ? 0 : (standing.wins / standing.played * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _Stat(label: l10n.profileRank(standing.rank, state.playerCount)),
            _Stat(label: formatRating(standing.rating)),
            _Stat(
              label: l10n.leaderboardRecord(
                standing.wins,
                standing.losses,
                standing.draws,
              ),
            ),
            _Stat(label: l10n.profileWinRate(winRate)),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.profileTrendTitle,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (state.history.length < 2)
          EmptyState(message: l10n.profileNotEnoughMatches)
        else ...[
          RatingTrendChart(points: state.history),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              RatingDelta(value: state.history.last.ratingDelta),
            ],
          ),
        ],
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}

