import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/failure_text.dart';
import '../../../../core/widgets/sheet.dart';
import '../../../../core/widgets/tag.dart';
import '../../../../core/widgets/trophy_chip.dart';
import '../../../auth/presentation/cubit/auth_bloc.dart';
import '../../../competition/presentation/cubit/competition_cubit.dart';
import '../../domain/bracket.model.dart';
import '../../domain/tournament_run.model.dart';
import '../cubit/tournament_cubit.dart';
import '../widgets/bracket_view.dart';
import 'tournament_score_sheet.dart';

Future<void> showTournamentBracketSheet(
  BuildContext context, {
  required TournamentCubit cubit,
  required String tournamentId,
}) {
  return showAdaptiveSheet<void>(
    context,
    builder: (_) => BlocProvider<TournamentCubit>.value(
      value: cubit,
      child: TournamentBracketSheet(tournamentId: tournamentId),
    ),
  );
}

class TournamentBracketSheet extends StatelessWidget {
  const TournamentBracketSheet({super.key, required this.tournamentId});

  final String tournamentId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TournamentCubit, TournamentState>(
      builder: (context, state) {
        final run = _run(state);

        return Sheet(
          title: context.l10n.tournamentBracketTitle,
          content: _content(context, state, run),
          secondaryButton: _discardButton(context, state, run),
        );
      },
    );
  }

  TournamentRun? _run(TournamentState state) =>
      state is TournamentReady ? state.runOf(tournamentId) : null;

  Widget _content(
    BuildContext context,
    TournamentState state,
    TournamentRun? run,
  ) {
    if (run == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (run.champion case final champion?) ...[
          _champion(context, champion),
          const SizedBox(height: AppSpacing.md),
        ],
        BracketView(
          bracket: run.bracket,
          myPlayerId: context.watch<CompetitionCubit>().state.myPlayerId,
          onSelect: _canScore(context, run)
              ? (match) => _score(context, match)
              : null,
        ),
        if (state case TournamentReady(actionFailure: final failure?))
          FailureText(failure),
      ],
    );
  }

  Widget _champion(BuildContext context, TournamentEntrant champion) {
    return Row(
      children: [
        const TrophyChip(count: 1, iconSize: 20),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            champion.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.titleSmall,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Tag(context.l10n.tournamentChampion, color: AppColors.gold),
      ],
    );
  }

  bool _canScore(BuildContext context, TournamentRun run) =>
      context.read<AuthBloc>().state.canWrite && !run.isCompleted;

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

  Widget? _discardButton(
    BuildContext context,
    TournamentState state,
    TournamentRun? run,
  ) {
    if (state is! TournamentReady || run == null) return null;

    final session = context.watch<AuthBloc>().state;
    final ownerId = context.watch<CompetitionCubit>().state.competition?.ownerId;
    if (ownerId == null || !session.canWrite) return null;
    if (!run.tournament.isManageableBy(session.user?.id, ownerId: ownerId)) {
      return null;
    }

    return AdaptiveButton(
      label: _discardLabel(context, run),
      kind: AdaptiveButtonKind.destructive,
      busy: state.busy,
      onPressed: () => _confirmDiscard(context, run),
    );
  }

  Future<void> _confirmDiscard(BuildContext context, TournamentRun run) async {
    final navigator = Navigator.of(context);
    final cubit = context.read<TournamentCubit>();

    final confirmed = await showAdaptiveConfirm(
      context,
      title: run.isCompleted
          ? context.l10n.tournamentRemoveTitle
          : context.l10n.tournamentCancelTitle,
      message: context.l10n.tournamentCancelConfirm,
      confirmLabel: _discardLabel(context, run),
      cancelLabel: context.l10n.tournamentKeep,
      destructive: true,
    );
    if (!confirmed) return;

    final cancelled = await cubit.cancel(tournamentId);
    if (cancelled && navigator.mounted) navigator.pop();
  }

  String _discardLabel(BuildContext context, TournamentRun run) =>
      run.isCompleted
      ? context.l10n.tournamentRemove
      : context.l10n.tournamentCancel;
}
