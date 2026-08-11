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
          MatchFormStatus.ready => Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: _Form(
              state: state,
              scoreA: _scoreA,
              scoreB: _scoreB,
              onSubmit: _submit,
            ),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _TeamArea(
                  key: const Key('teamAreaA'),
                  title: l10n.matchTeamA,
                  color: AdaptiveColors.teamA(context),
                  members: state.teamA,
                  rating: state.teamRating(MatchTeam.a),
                  ratingOf: state.ratingOf,
                  placeholder: l10n.matchTapToSelectPlayers,
                  onTap: () => _pickTeam(context, state, MatchTeam.a),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _TeamArea(
                  key: const Key('teamAreaB'),
                  title: l10n.matchTeamB,
                  color: AdaptiveColors.teamB(context),
                  members: state.teamB,
                  rating: state.teamRating(MatchTeam.b),
                  ratingOf: state.ratingOf,
                  placeholder: l10n.matchTapToSelectPlayers,
                  onTap: () => _pickTeam(context, state, MatchTeam.b),
                ),
              ),
            ],
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
                accentColor: AdaptiveColors.teamA(context),
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
                accentColor: AdaptiveColors.teamB(context),
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

Future<void> _pickTeam(
  BuildContext context,
  MatchFormState state,
  MatchTeam side,
) async {
  final l10n = AppLocalizations.of(context);
  final cubit = context.read<MatchFormCubit>();
  final color = side == MatchTeam.a
      ? AdaptiveColors.teamA(context)
      : AdaptiveColors.teamB(context);

  final otherSide = side.opposite;
  final selected = await showAdaptiveSheet<Set<String>>(
    context,
    builder: (_) => _TeamPickerSheet(
      key: const Key('teamPickerSheet'),
      title: side == MatchTeam.a ? l10n.matchTeamA : l10n.matchTeamB,
      color: color,
      players: state.players
          .where((player) => state.assignments[player.id] != otherSide)
          .toList(growable: false),
      initiallySelected: state.team(side).map((player) => player.id).toSet(),
    ),
  );
  if (selected != null) cubit.setTeam(side, selected);
}

List<Player> _sortedByName(List<Player> players) {
  final sorted = List<Player>.of(players);
  sorted.sort(
    (a, b) =>
        a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
  );
  return sorted;
}

class _TeamArea extends StatelessWidget {
  const _TeamArea({
    super.key,
    required this.title,
    required this.color,
    required this.members,
    required this.rating,
    required this.ratingOf,
    required this.placeholder,
    required this.onTap,
  });

  final String title;
  final Color color;
  final List<Player> members;
  final double rating;
  final double Function(String playerId) ratingOf;
  final String placeholder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 88),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: AppRadius.card,
          color: color.withValues(alpha: 0.10),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
                if (members.isNotEmpty)
                  Text(
                    formatRating(rating),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: color,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (members.isEmpty)
              Text(
                placeholder,
                style: const TextStyle(color: AppColors.neutral, fontSize: 13),
              )
            else
              for (final player in _sortedByName(members))
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          player.displayName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        formatRating(ratingOf(player.id)),
                        style: const TextStyle(
                          color: AppColors.neutral,
                          fontSize: 12,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _TeamPickerSheet extends StatefulWidget {
  const _TeamPickerSheet({
    super.key,
    required this.title,
    required this.color,
    required this.players,
    required this.initiallySelected,
  });

  final String title;
  final Color color;
  final List<Player> players;
  final Set<String> initiallySelected;

  @override
  State<_TeamPickerSheet> createState() => _TeamPickerSheetState();
}

class _TeamPickerSheetState extends State<_TeamPickerSheet> {
  late final Set<String> _selected = Set.of(widget.initiallySelected);

  void _toggle(String playerId) {
    setState(() {
      if (!_selected.remove(playerId)) _selected.add(playerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Text(
                widget.title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: widget.color,
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final player in _sortedByName(widget.players))
                      _SelectablePlayerRow(
                        player: player,
                        color: widget.color,
                        selected: _selected.contains(player.id),
                        onTap: () => _toggle(player.id),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: AdaptiveButton(
                label: l10n.commonDone,
                onPressed: () => Navigator.of(context).pop(_selected),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectablePlayerRow extends StatelessWidget {
  const _SelectablePlayerRow({
    required this.player,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Player player;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.card,
            color: selected
                ? color.withValues(alpha: 0.14)
                : AppColors.neutral.withValues(alpha: 0.08),
            border: Border.all(
              color: selected ? color : const Color(0x00000000),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  player.displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _CheckMark(selected: selected, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckMark extends StatelessWidget {
  const _CheckMark({required this.selected, required this.color});

  final bool selected;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? color : null,
        border: Border.all(
          color: selected ? color : AppColors.neutral.withValues(alpha: 0.35),
        ),
      ),
      child: selected
          ? const AdaptiveIcon(
              AdaptiveGlyph.check,
              color: Color(0xFFFFFFFF),
              size: 14,
            )
          : null,
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
    final colorA = AdaptiveColors.teamA(context);
    final colorB = AdaptiveColors.teamB(context);

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
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AdaptiveColors.accent(context),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.matchTeamA,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colorA,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  l10n.matchTeamB,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colorB,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final player in state.teamA)
                      Text(
                        player.displayName,
                        style: const TextStyle(fontSize: 14),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final player in state.teamB)
                      Text(
                        player.displayName,
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontSize: 14),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.matchTeamRating(formatRating(preview.teamARating)),
                  style: const TextStyle(
                    color: AppColors.neutral,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  l10n.matchTeamRating(formatRating(preview.teamBRating)),
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: AppColors.neutral,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(child: RatingDelta(value: preview.deltaA, fontSize: 18)),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: RatingDelta(value: preview.deltaB, fontSize: 18),
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
