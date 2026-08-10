import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure_messages.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/rating_delta.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../player/domain/player.dart';
import '../../domain/match_entry.dart';
import '../cubit/match_form_cubit.dart';

class NewMatchPage extends StatefulWidget {
  const NewMatchPage({super.key});

  @override
  State<NewMatchPage> createState() => _NewMatchPageState();
}

class _NewMatchPageState extends State<NewMatchPage> {
  final _scoreA = TextEditingController();
  final _scoreB = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<MatchFormCubit>().load();
  }

  @override
  void dispose() {
    _scoreA.dispose();
    _scoreB.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final id = await context.read<MatchFormCubit>().submit();
    if (id != null && mounted) context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<MatchFormCubit>();

    return AdaptiveScaffold(
      title: l10n.matchNewTitle,
      body: BlocConsumer<MatchFormCubit, MatchFormState>(
        // swapSides rewrites both scores, so the fields follow the state
        // rather than the other way round.
        listenWhen: (previous, current) =>
            previous.scoreA != current.scoreA ||
            previous.scoreB != current.scoreB,
        listener: (context, state) {
          if (_scoreA.text != state.scoreA) _scoreA.text = state.scoreA;
          if (_scoreB.text != state.scoreB) _scoreB.text = state.scoreB;
        },
        builder: (context, state) => switch (state.status) {
          MatchFormStatus.loading => const AdaptiveLoader(),
          MatchFormStatus.missing => EmptyState(
            message: l10n.competitionNotFound,
          ),
          MatchFormStatus.failed => ErrorRetry(
            message: state.failure!.localized(l10n),
            retryLabel: l10n.commonRetry,
            onRetry: cubit.load,
          ),
          MatchFormStatus.ready => SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: _Form(state: state, scoreA: _scoreA, scoreB: _scoreB, onSubmit: _submit),
          ),
        },
      ),
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({
    required this.state,
    required this.scoreA,
    required this.scoreB,
    required this.onSubmit,
  });

  final MatchFormState state;
  final TextEditingController scoreA;
  final TextEditingController scoreB;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<MatchFormCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.matchPickTeamsTitle,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.matchPickTeamsHelp,
          style: const TextStyle(color: AppColors.neutral, fontSize: 13),
        ),
        const SizedBox(height: AppSpacing.md),

        if (state.players.isEmpty)
          EmptyState(message: l10n.matchNeedsPlayers)
        else
          for (final player in state.players)
            _PlayerRow(
              player: player,
              rating: state.ratingOf(player.id),
              side: state.assignments[player.id],
              onAssign: (side) => cubit.assign(player.id, side),
            ),

        if (state.assignments.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AdaptiveButton(
                  label: l10n.matchSwapSides,
                  kind: AdaptiveButtonKind.plain,
                  expand: false,
                  onPressed: cubit.swapSides,
                ),
                AdaptiveButton(
                  label: l10n.matchClearTeams,
                  kind: AdaptiveButtonKind.plain,
                  expand: false,
                  onPressed: cubit.clearTeams,
                ),
              ],
            ),
          ),

        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.matchScoreTitle,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AdaptiveTextField(
                label: l10n.matchScoreTeam(l10n.matchTeamA),
                controller: scoreA,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 3,
                onChanged: cubit.scoreAChanged,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AdaptiveTextField(
                label: l10n.matchScoreTeam(l10n.matchTeamB),
                controller: scoreB,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 3,
                onChanged: cubit.scoreBChanged,
              ),
            ),
          ],
        ),

        if (state.preview != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _PreviewCard(state: state),
        ],

        const SizedBox(height: AppSpacing.lg),

        if (_hint(state, l10n) case final hint?)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              hint,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.neutral, fontSize: 13),
            ),
          ),

        AdaptiveButton(
          label: l10n.matchSubmit,
          busy: state.busy,
          onPressed: state.canSubmit ? onSubmit : null,
        ),

        if (state.submitFailure != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Text(
              state.submitFailure!.localized(l10n),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.negative),
            ),
          ),

        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  String? _hint(MatchFormState state, AppLocalizations l10n) {
    if (state.players.isEmpty) return null;
    if (!state.teamsAreValid) return l10n.matchNeedsBothTeams;
    if (!state.scoresAreValid) return l10n.matchScoreMissing;
    if (state.drawIsRefused) return l10n.matchDrawNotAllowed;
    return null;
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.player,
    required this.rating,
    required this.side,
    required this.onAssign,
  });

  final Player player;
  final double rating;
  final MatchTeam? side;
  final void Function(MatchTeam side) onAssign;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          borderRadius: AppRadius.card,
          color: AppColors.neutral.withValues(alpha: 0.08),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    player.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    side == null ? l10n.matchBench : formatRating(rating),
                    style: const TextStyle(
                      color: AppColors.neutral,
                      fontSize: 12,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            _SideToggle(
              label: 'A',
              color: AdaptiveColors.teamA(context),
              selected: side == MatchTeam.a,
              onTap: () => onAssign(MatchTeam.a),
            ),
            const SizedBox(width: AppSpacing.sm),
            _SideToggle(
              label: 'B',
              color: AdaptiveColors.teamB(context),
              selected: side == MatchTeam.b,
              onTap: () => onAssign(MatchTeam.b),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideToggle extends StatelessWidget {
  const _SideToggle({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 44,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          color: selected ? color : color.withValues(alpha: 0.10),
          border: Border.all(
            color: selected ? color : AppColors.neutral.withValues(alpha: 0.35),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: selected ? const Color(0xFFFFFFFF) : color,
          ),
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.state});

  final MatchFormState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final preview = state.preview!;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: AppRadius.card,
        color: AdaptiveColors.accent(context).withValues(alpha: 0.10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.matchPreviewTitle,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _PreviewSide(
                  title: l10n.matchTeamA,
                  color: AdaptiveColors.teamA(context),
                  rating: preview.teamARating,
                  delta: preview.deltaA,
                  members: state.teamA,
                  alignEnd: false,
                ),
              ),
              Expanded(
                child: _PreviewSide(
                  title: l10n.matchTeamB,
                  color: AdaptiveColors.teamB(context),
                  rating: preview.teamBRating,
                  delta: preview.deltaB,
                  members: state.teamB,
                  alignEnd: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.matchPreviewCaveat,
            style: const TextStyle(color: AppColors.neutral, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _PreviewSide extends StatelessWidget {
  const _PreviewSide({
    required this.title,
    required this.color,
    required this.rating,
    required this.delta,
    required this.members,
    required this.alignEnd,
  });

  final String title;
  final Color color;
  final double rating;
  final double delta;
  final List<Player> members;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          members.map((player) => player.displayName).join(' & '),
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.matchTeamRating(formatRating(rating)),
          style: const TextStyle(color: AppColors.neutral, fontSize: 12),
        ),
        const SizedBox(height: 2),
        RatingDelta(value: delta, fontSize: 18),
      ],
    );
  }
}
