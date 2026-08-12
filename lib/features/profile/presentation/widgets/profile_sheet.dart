import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure_messages.dart';
import '../../../../core/extensions/build_context_l10n.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/rating_delta.dart';
import '../../../../core/widgets/sheet.dart';
import '../../../../core/widgets/stat_label.dart';
import '../../../../core/widgets/state_views.dart';
import '../cubit/profile_cubit.dart';
import 'initials_circle.dart';
import 'rating_trend_chart.dart';

class ProfileSheet extends StatelessWidget {
  const ProfileSheet({super.key, required this.displayName});
  final String displayName;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProfileCubit>();

    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        return Sheet(
          title: displayName,
          avatar: InitialsCircle(displayName: displayName, size: 48),
          content: switch (state.status) {
            ProfileStatus.loading => const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: AdaptiveLoader(),
            ),
            ProfileStatus.failed => ErrorRetry(
              message: state.failure!.localized(context.l10n),
              retryLabel: context.l10n.commonRetry,
              onRetry: cubit.load,
            ),
            ProfileStatus.ready => _ready(context, state),
          },
        );
      },
    );
  }

  Widget _ready(BuildContext context, ProfileState state) {
    final standing = state.standing;

    if (standing == null) {
      return EmptyState(message: context.l10n.profileNotEnoughMatches);
    }

    final winRate = standing.played == 0
        ? 0
        : (standing.wins / standing.played * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            StatLabel(
              label: context.l10n.profileRank(standing.rank, state.playerCount),
            ),
            StatLabel(label: formatRating(standing.rating)),
            StatLabel(
              label: context.l10n.leaderboardRecord(
                standing.wins,
                standing.losses,
                standing.draws,
              ),
            ),
            StatLabel(label: context.l10n.profileWinRate(winRate)),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          context.l10n.profileTrendTitle,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (state.history.length < 2)
          EmptyState(message: context.l10n.profileNotEnoughMatches)
        else ...[
          RatingTrendChart(points: state.history),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [RatingDelta(value: state.history.last.ratingDelta)],
          ),
        ],
      ],
    );
  }
}
