import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/dependency_injection/injector.dart';
import '../../../../core/error/failure_messages.dart';
import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/extensions/double.extension.dart';
import '../../../../core/extensions/text_editing_controller.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/sheet.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/tag.dart';
import '../../../competition/presentation/cubit/competition_cubit.dart';
import '../../../player/domain/player.model.dart';
import '../../domain/match_entry.model.dart';
import '../cubit/match_form_cubit.dart';
import 'new_match_keys.enum.dart';
import 'team_picker_sheet.dart';

Future<void> showNewMatchSheet(
  BuildContext context, {
  required String competitionId,
}) {
  return showAdaptiveSheet<void>(
    context,
    confirmsDismissal: true,
    builder: (_) => BlocProvider(
      create: (_) => getIt<MatchFormCubit>(param1: competitionId)..load(),
      child: const NewMatchSheet(),
    ),
  );
}

class NewMatchSheet extends StatefulWidget {
  const NewMatchSheet({super.key});

  @override
  State<NewMatchSheet> createState() => _NewMatchSheetState();
}

class _NewMatchSheetState extends State<NewMatchSheet> {
  final _scoreA = TextEditingController();
  final _scoreB = TextEditingController();

  @override
  void dispose() {
    _scoreA.dispose();
    _scoreB.dispose();
    super.dispose();
  }

  int? get _scoreAValue => _scoreA.intValue;
  int? get _scoreBValue => _scoreB.intValue;

  Future<void> _submit(BuildContext context, MatchFormCubit cubit) async {
    final scoreA = _scoreAValue;
    final scoreB = _scoreBValue;
    if (scoreA == null || scoreB == null) return;

    final id = await cubit.submit(scoreA: scoreA, scoreB: scoreB);
    if (id == null || !context.mounted) return;

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MatchFormCubit>();
    final myPlayerId = context.watch<CompetitionCubit>().state.myPlayerId;

    return BlocBuilder<MatchFormCubit, MatchFormState>(
      builder: (context, state) => PopScope(
        canPop: !_hasUnsavedInput(state),
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _confirmDiscard(context);
        },
        child: Sheet(
          title: context.l10n.matchNewTitle,
          content: _content(context, state, cubit, myPlayerId),
          primaryButton: state is MatchFormReady
              ? AdaptiveButton(
                  label: context.l10n.matchSubmit,
                  busy: state.busy,
                  onPressed:
                      state.canSubmit(
                        scoreAValue: _scoreAValue,
                        scoreBValue: _scoreBValue,
                      )
                      ? () => _submit(context, cubit)
                      : null,
                )
              : null,
        ),
      ),
    );
  }

  bool _hasUnsavedInput(MatchFormState state) {
    return _scoreA.text.isNotEmpty ||
        _scoreB.text.isNotEmpty ||
        (state is MatchFormReady && state.assignments.isNotEmpty);
  }

  Future<void> _confirmDiscard(BuildContext context) async {
    final navigator = Navigator.of(context);
    final discard = await showAdaptiveConfirm(
      context,
      title: context.l10n.matchDiscardTitle,
      message: context.l10n.matchDiscardConfirm,
      confirmLabel: context.l10n.matchDiscard,
      cancelLabel: context.l10n.matchKeepEditing,
      destructive: true,
    );
    if (discard) navigator.pop();
  }

  Widget _content(
    BuildContext context,
    MatchFormState state,
    MatchFormCubit cubit,
    String? myPlayerId,
  ) {
    return switch (state) {
      MatchFormLoading() => const Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: AdaptiveLoader(),
      ),
      MatchFormMissing() => EmptyState(
        message: context.l10n.competitionNotFound,
      ),
      MatchFormFailed(:final failure) => ErrorRetry(
        message: failure.localized(context.l10n),
        retryLabel: context.l10n.commonRetry,
        onRetry: cubit.load,
      ),
      MatchFormReady() => _form(context, state, myPlayerId),
    };
  }

  Widget _form(BuildContext context, MatchFormReady state, String? myPlayerId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(context.l10n.matchPickTeamsTitle, style: AppTypography.titleSmall),
        const SizedBox(height: AppSpacing.md),

        if (state.players.isEmpty)
          EmptyState(message: context.l10n.matchNeedsPlayers)
        else
          _teamsRow(context, state, myPlayerId),

        const SizedBox(height: AppSpacing.lg),
        Text(context.l10n.matchScoreTitle, style: AppTypography.titleSmall),
        const SizedBox(height: AppSpacing.md),
        _scoreFields(context),

        if (_hint(state, context) case final hint?) ...[
          const SizedBox(height: AppSpacing.md),
          _hintText(hint),
        ],

        if (state.submitFailure != null) _submitFailureText(context, state),
      ],
    );
  }

  Widget _teamsRow(
    BuildContext context,
    MatchFormReady state,
    String? myPlayerId,
  ) {
    return Row(
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
            myPlayerId: myPlayerId,
            onTap: () => _pickTeam(context, state, MatchTeam.a, myPlayerId),
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
            myPlayerId: myPlayerId,
            onTap: () => _pickTeam(context, state, MatchTeam.b, myPlayerId),
          ),
        ),
      ],
    );
  }

  Widget _scoreFields(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AdaptiveTextField(
            label: context.l10n.matchTeamA.toUpperCase(),
            controller: _scoreA,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 3,
            onChanged: (_) => setState(() {}),
            accentColor: AdaptiveColors.teamA(context),
            labelFontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: AdaptiveTextField(
            label: context.l10n.matchTeamB.toUpperCase(),
            controller: _scoreB,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 3,
            onChanged: (_) => setState(() {}),
            accentColor: AdaptiveColors.teamB(context),
            labelFontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _hintText(String hint) {
    return Text(
      hint,
      textAlign: TextAlign.center,
      style: AppTypography.caption,
    );
  }

  Widget _submitFailureText(BuildContext context, MatchFormReady state) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Text(
        state.submitFailure!.localized(context.l10n),
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.negative),
      ),
    );
  }

  String? _hint(MatchFormReady state, BuildContext context) {
    if (state.players.isEmpty) return null;
    if (!state.teamsAreValid) return context.l10n.matchNeedsBothTeams;
    if (!state.scoresAreValid(
      scoreAValue: _scoreAValue,
      scoreBValue: _scoreBValue,
    )) {
      return context.l10n.matchScoreMissing;
    }
    if (state.drawIsRefused(
      scoreAValue: _scoreAValue,
      scoreBValue: _scoreBValue,
    )) {
      return context.l10n.matchDrawNotAllowed;
    }
    return null;
  }

  Future<void> _pickTeam(
    BuildContext context,
    MatchFormReady state,
    MatchTeam side,
    String? myPlayerId,
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
        myPlayerId: myPlayerId,
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
    required String? myPlayerId,
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
          color: color.withValues(alpha: AppOpacity.accentFill),
          border: Border.all(
            color: color.withValues(alpha: AppOpacity.fieldBorder),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _teamAreaHeader(
              title: title,
              color: color,
              members: members,
              rating: rating,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (members.isEmpty)
              Text(placeholder, style: AppTypography.caption)
            else
              for (final player in _sortedByName(members))
                _teamMemberRow(context, player, ratingOf, myPlayerId),
          ],
        ),
      ),
    );
  }

  Widget _teamAreaHeader({
    required String title,
    required Color color,
    required List<Player> members,
    required double rating,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Transform.translate(
            offset: const Offset(0, 4),
            child: Text(
              title.toUpperCase(),
              style: AppTypography.eyebrow.copyWith(color: color),
            ),
          ),
        ),
        if (members.isNotEmpty)
          TweenAnimationBuilder<double>(
            tween: Tween<double>(end: rating),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            builder: (_, value, _) => Text(
              value.ratingLabel,
              style: AppTypography.headlineMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
      ],
    );
  }

  Widget _teamMemberRow(
    BuildContext context,
    Player player,
    double Function(String playerId) ratingOf,
    String? myPlayerId,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    player.displayName,
                    style: AppTypography.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (player.id == myPlayerId) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Tag(
                    context.l10n.playersYou,
                    color: AdaptiveColors.accent(context),
                  ),
                ],
              ],
            ),
          ),
          Text(
            ratingOf(player.id).ratingLabel,
            style: AppTypography.captionSmall.copyWith(
              fontFeatures: AppTypography.tabularFigures,
            ),
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
