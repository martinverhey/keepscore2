import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/dependency_injection/injector.dart';
import '../../../../core/error/failure_messages.dart';
import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/extensions/competition.extension.dart';
import '../../../../core/extensions/text_editing_controller.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/sheet.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/cubit/auth_bloc.dart';
import '../../../competition/presentation/cubit/competition_cubit.dart';
import '../../../player/domain/player.model.dart';
import '../../../player/presentation/widgets/manage_players_sheet.dart';
import '../../domain/match_entry.model.dart';
import '../cubit/match_form_cubit.dart';
import 'new_match_keys.enum.dart';
import 'team_area.dart';
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
          child: TeamArea(
            key: const ValueKey(NewMatchKey.teamAreaA),
            title: context.l10n.matchTeamA,
            color: AdaptiveColors.teamA(context),
            members: _members(state, MatchTeam.a),
            rating: state.teamRating(MatchTeam.a),
            placeholder: context.l10n.matchTapToSelectPlayers,
            myPlayerId: myPlayerId,
            onTap: () => _pickTeam(context, state, MatchTeam.a, myPlayerId),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: TeamArea(
            key: const ValueKey(NewMatchKey.teamAreaB),
            title: context.l10n.matchTeamB,
            color: AdaptiveColors.teamB(context),
            members: _members(state, MatchTeam.b),
            rating: state.teamRating(MatchTeam.b),
            placeholder: context.l10n.matchTapToSelectPlayers,
            myPlayerId: myPlayerId,
            onTap: () => _pickTeam(context, state, MatchTeam.b, myPlayerId),
          ),
        ),
      ],
    );
  }

  List<TeamAreaMember> _members(MatchFormReady state, MatchTeam team) {
    return state
        .team(team)
        .map(
          (player) => TeamAreaMember(
            id: player.id,
            displayName: player.displayName,
            rating: state.ratingOf(player.id),
          ),
        )
        .toList(growable: false);
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
    final session = context.read<AuthBloc>().state;
    final competition = context.read<CompetitionCubit>().state.competition;
    final color = side == MatchTeam.a
        ? AdaptiveColors.teamA(context)
        : AdaptiveColors.teamB(context);

    final selected = await showAdaptiveSheet<Set<String>>(
      context,
      builder: (_) => TeamPickerSheet(
        key: const ValueKey(NewMatchKey.teamPickerSheet),
        title: side == MatchTeam.a
            ? context.l10n.matchTeamA
            : context.l10n.matchTeamB,
        color: color,
        players: _selectablePlayers(state, side),
        initiallySelected: state.team(side).map((player) => player.id).toSet(),
        onManagePlayers: () => _managePlayers(context, cubit, side),
        canManagePlayers:
            session.canWrite && competition.isOwnedBySession(session),
        myPlayerId: myPlayerId,
      ),
    );
    if (!context.mounted) return;
    await cubit.refreshPlayers();
    if (selected != null) cubit.setTeam(side, selected);
  }

  Future<List<Player>> _managePlayers(
    BuildContext context,
    MatchFormCubit cubit,
    MatchTeam side,
  ) async {
    await showManagePlayersSheet(context, competitionId: cubit.competitionId);
    await cubit.refreshPlayers();
    final state = cubit.state;
    if (state is! MatchFormReady) return const [];
    return _selectablePlayers(state, side);
  }
}

List<Player> _selectablePlayers(MatchFormReady state, MatchTeam side) {
  final otherSide = side.opposite;
  return state.players
      .where((player) => state.assignments[player.id] != otherSide)
      .toList(growable: false);
}
