import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/failure_text.dart';
import '../../../../core/widgets/sheet.dart';
import '../../../../core/widgets/trophy_chip.dart';
import '../../../auth/presentation/cubit/auth_bloc.dart';
import '../../../competition/presentation/cubit/competition_cubit.dart';
import '../../domain/bracket.model.dart';
import '../cubit/tournament_cubit.dart';
import '../widgets/bracket_view.dart';
import 'tournament_score_sheet.dart';

Future<void> showTournamentBracketSheet(
  BuildContext context, {
  required TournamentCubit cubit,
}) {
  return showAdaptiveSheet<void>(
    context,
    builder: (_) => BlocProvider<TournamentCubit>.value(
      value: cubit,
      child: const TournamentBracketSheet(),
    ),
  );
}

class TournamentBracketSheet extends StatelessWidget {
  const TournamentBracketSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TournamentCubit, TournamentState>(
      builder: (context, state) => Sheet(
        title: context.l10n.tournamentBracketTitle,
        content: _content(context, state),
        secondaryButton: _cancelButton(context, state),
      ),
    );
  }

  Widget _content(BuildContext context, TournamentState state) {
    if (state is! TournamentReady) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (state.champion case final champion?) ...[
          _champion(context, champion),
          const SizedBox(height: AppSpacing.md),
        ],
        BracketView(
          bracket: state.bracket,
          onSelect: _canScore(context, state)
              ? (match) => _score(context, match)
              : null,
        ),
        if (state.actionFailure case final failure?) FailureText(failure),
      ],
    );
  }

  Widget _champion(BuildContext context, TournamentEntrant champion) {
    return Row(
      children: [
        const TrophyChip(count: 1, iconSize: 20),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.l10n.tournamentChampion,
                style: AppTypography.eyebrow.copyWith(color: AppColors.gold),
              ),
              Text(
                champion.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleSmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _canScore(BuildContext context, TournamentReady state) =>
      context.read<AuthBloc>().state.canWrite && !state.isCompleted;

  Future<void> _score(BuildContext context, TournamentMatch match) async {
    final cubit = context.read<TournamentCubit>();
    final scores = await showTournamentScoreSheet(context, match: match);
    if (scores == null) return;

    await cubit.setResult(
      tournamentMatchId: match.id,
      scoreA: scores.$1,
      scoreB: scores.$2,
    );
  }

  Widget? _cancelButton(BuildContext context, TournamentState state) {
    if (state is! TournamentReady) return null;

    final session = context.watch<AuthBloc>().state;
    final ownerId = context.watch<CompetitionCubit>().state.competition?.ownerId;
    if (ownerId == null || !session.canWrite) return null;
    if (!state.tournament.isManageableBy(session.user?.id, ownerId: ownerId)) {
      return null;
    }

    return AdaptiveButton(
      label: context.l10n.tournamentCancel,
      kind: AdaptiveButtonKind.destructive,
      busy: state.busy,
      onPressed: () => _confirmCancel(context),
    );
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final navigator = Navigator.of(context);
    final cubit = context.read<TournamentCubit>();

    final confirmed = await showAdaptiveConfirm(
      context,
      title: context.l10n.tournamentCancelTitle,
      message: context.l10n.tournamentCancelConfirm,
      confirmLabel: context.l10n.tournamentCancel,
      cancelLabel: context.l10n.tournamentKeep,
      destructive: true,
    );
    if (!confirmed) return;

    final cancelled = await cubit.cancel();
    if (cancelled && navigator.mounted) navigator.pop();
  }
}
