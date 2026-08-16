import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure_messages.dart';
import '../../../../core/extensions/build_context_l10n.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/rating_delta.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../player/domain/player.model.dart';
import '../../domain/match_entry.model.dart';
import '../cubit/match_form_cubit.dart';
import '../widgets/team_picker_sheet.dart';
import 'new_match_keys.enum.dart';

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
    final cubit = context.read<MatchFormCubit>();

    return AdaptiveScaffold(
      title: context.l10n.matchNewTitle,
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
            message: context.l10n.competitionNotFound,
          ),
          MatchFormStatus.failed => ErrorRetry(
            message: state.failure!.localized(context.l10n),
            retryLabel: context.l10n.commonRetry,
            onRetry: cubit.load,
          ),
          MatchFormStatus.ready => Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: _form(context, state),
          ),
        },
      ),
    );
  }

  Widget _form(BuildContext context, MatchFormState state) {
    final cubit = context.read<MatchFormCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.matchPickTeamsTitle,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          context.l10n.matchPickTeamsHelp,
          style: const TextStyle(color: AppColors.neutral, fontSize: 13),
        ),
        const SizedBox(height: AppSpacing.md),

        if (state.players.isEmpty)
          EmptyState(message: context.l10n.matchNeedsPlayers)
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _teamArea(
                  context,
                  key: const ValueKey(NewMatchKey.teamAreaA),
                  title: context.l10n.matchTeamA,
                  color: AdaptiveColors.teamA(context),
                  members: state.teamA,
                  rating: state.teamRating(MatchTeam.a),
                  ratingOf: state.ratingOf,
                  placeholder: context.l10n.matchTapToSelectPlayers,
                  onTap: () => _pickTeam(context, state, MatchTeam.a),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _teamArea(
                  context,
                  key: const ValueKey(NewMatchKey.teamAreaB),
                  title: context.l10n.matchTeamB,
                  color: AdaptiveColors.teamB(context),
                  members: state.teamB,
                  rating: state.teamRating(MatchTeam.b),
                  ratingOf: state.ratingOf,
                  placeholder: context.l10n.matchTapToSelectPlayers,
                  onTap: () => _pickTeam(context, state, MatchTeam.b),
                ),
              ),
            ],
          ),

        const SizedBox(height: AppSpacing.lg),
        Text(
          context.l10n.matchScoreTitle,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AdaptiveTextField(
                label: context.l10n.matchScoreTeam(
                  context.l10n.matchTeamA.toUpperCase(),
                ),
                controller: _scoreA,
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
                label: context.l10n.matchScoreTeam(
                  context.l10n.matchTeamB.toUpperCase(),
                ),
                controller: _scoreB,
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
          _previewCard(context, state),
        ],

        const SizedBox(height: AppSpacing.lg),

        if (_hint(state, context) case final hint?)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              hint,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.neutral, fontSize: 13),
            ),
          ),

        AdaptiveButton(
          label: context.l10n.matchSubmit,
          busy: state.busy,
          onPressed: state.canSubmit ? _submit : null,
        ),

        if (state.submitFailure != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Text(
              state.submitFailure!.localized(context.l10n),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.negative),
            ),
          ),

        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  String? _hint(MatchFormState state, BuildContext context) {
    if (state.players.isEmpty) return null;
    if (!state.teamsAreValid) return context.l10n.matchNeedsBothTeams;
    if (!state.scoresAreValid) return context.l10n.matchScoreMissing;
    if (state.drawIsRefused) return context.l10n.matchDrawNotAllowed;
    return null;
  }

  Future<void> _pickTeam(
    BuildContext context,
    MatchFormState state,
    MatchTeam side,
  ) async {
    final cubit = context.read<MatchFormCubit>();
    final color = side == MatchTeam.a
        ? AdaptiveColors.teamA(context)
        : AdaptiveColors.teamB(context);

    final otherSide = side.opposite;
    final selected = await showAdaptiveSheet<Set<String>>(
      context,
      builder: (_) => TeamPickerSheet(
        key: const ValueKey(NewMatchKey.teamPickerSheet),
        title: side == MatchTeam.a
            ? context.l10n.matchTeamA
            : context.l10n.matchTeamB,
        color: color,
        players: state.players
            .where((player) => state.assignments[player.id] != otherSide)
            .toList(growable: false),
        initiallySelected: state.team(side).map((player) => player.id).toSet(),
        competitionId: cubit.competitionId,
      ),
    );
    if (!context.mounted) return;
    await cubit.refreshPlayers();
    if (selected != null) cubit.setTeam(side, selected);
  }

  Widget _teamArea(
    BuildContext context, {
    Key? key,
    required String title,
    required Color color,
    required List<Player> members,
    required double rating,
    required double Function(String playerId) ratingOf,
    required String placeholder,
    required VoidCallback onTap,
  }) {
    return AdaptiveTappable(
      key: key,
      onTap: onTap,
      borderRadius: AppRadius.card,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: color,
                    ),
                  ),
                ),
                if (members.isNotEmpty)
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(end: rating),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    builder: (_, value, _) => Text(
                      formatRating(value),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: color,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
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

  Widget _previewCard(BuildContext context, MatchFormState state) {
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
            context.l10n.matchPreviewTitle,
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
                  context.l10n.matchTeamA,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colorA,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  context.l10n.matchTeamB,
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
                  context.l10n.matchTeamRating(
                    formatRating(preview.teamARating),
                  ),
                  style: const TextStyle(
                    color: AppColors.neutral,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  context.l10n.matchTeamRating(
                    formatRating(preview.teamBRating),
                  ),
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
            context.l10n.matchPreviewCaveat,
            style: const TextStyle(color: AppColors.neutral, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

List<Player> _sortedByName(List<Player> players) {
  final sorted = List<Player>.of(players);
  sorted.sort(
    (a, b) =>
        a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
  );
  return sorted;
}
