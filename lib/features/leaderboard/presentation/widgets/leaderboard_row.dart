import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/dependency_injection/injector.dart';
import '../../../../core/extensions/build_context_l10n.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/medal_chip.dart';
import '../../../../core/widgets/rating_delta.dart';
import '../../../competition/domain/competition.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../../profile/presentation/widgets/profile_sheet.dart';
import '../../domain/leaderboard.dart';
import '../../domain/medal_tally.dart';

class LeaderboardRow extends StatelessWidget {
  const LeaderboardRow({
    super.key,
    required this.competitionId,
    required this.standing,
    required this.isMe,
    required this.myPlayerId,
    required this.seasonLength,
    this.medals,
  });

  final String competitionId;
  final Leaderboard standing;
  final bool isMe;
  final String? myPlayerId;
  final SeasonLength seasonLength;
  final MedalTally? medals;

  Color? get _rankColor => switch (standing.rank) {
    1 => AppColors.gold,
    2 => AppColors.silver,
    3 => AppColors.bronze,
    _ => null,
  };

  void _openProfile(BuildContext context) => showAdaptiveSheet<void>(
    context,
    builder: (_) => BlocProvider(
      create: (_) =>
          getIt<ProfileCubit>(param1: competitionId, param2: standing.playerId)
            ..load(viewerPlayerId: myPlayerId),
      child: ProfileSheet(
        displayName: standing.displayName,
        seasonLength: seasonLength,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final badges = [
      if (isMe) context.l10n.playersYou,
      if (!standing.isClaimed) context.l10n.playersUnclaimed,
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openProfile(context),
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
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            standing.displayName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (medals != null && medals!.hasAny) ...[
                          const SizedBox(width: AppSpacing.sm),
                          ..._medalChips(medals!),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      standing.played == 0
                          ? context.l10n.leaderboardUnplayed
                          : [
                              context.l10n.leaderboardRecord(
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
      ),
    );
  }

  List<Widget> _medalChips(MedalTally medals) {
    final chips = [
      if (medals.gold > 0) MedalChip(color: AppColors.gold, count: medals.gold),
      if (medals.silver > 0)
        MedalChip(color: AppColors.silver, count: medals.silver),
      if (medals.bronze > 0)
        MedalChip(color: AppColors.bronze, count: medals.bronze),
    ];
    return [
      for (var i = 0; i < chips.length; i++) ...[
        if (i > 0) const SizedBox(width: AppSpacing.xs),
        chips[i],
      ],
    ];
  }
}
