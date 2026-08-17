import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/error/failure_messages.dart';
import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/extensions/double.extension.dart';
import '../../../../core/extensions/text_editing_controller.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/page_title.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/cubit/auth_bloc.dart';
import '../../../competition/presentation/cubit/competition_cubit.dart';
import '../../../competition/presentation/widgets/competition_section.enum.dart';
import '../../../competition/presentation/widgets/open_home.dart';
import '../../../competition/presentation/widgets/select_competition_section.dart';
import '../../../competition/presentation/widgets/sidebar.dart';
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

  int? get _scoreAValue => _scoreA.intValue;
  int? get _scoreBValue => _scoreB.intValue;

  Future<void> _submit() async {
    final scoreA = _scoreAValue;
    final scoreB = _scoreBValue;
    if (scoreA == null || scoreB == null) return;

    final id = await context.read<MatchFormCubit>().submit(
      scoreA: scoreA,
      scoreB: scoreB,
    );
    if (id != null && mounted) context.pop(true);
  }

  void _selectSection(CompetitionSection section) => selectCompetitionSection(
    context,
    competitionId: context.read<MatchFormCubit>().competitionId,
    target: section,
  );

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MatchFormCubit>();
    final session = context.watch<AuthBloc>().state;
    final competition = context.watch<CompetitionCubit>().state.competition;
    final isOwner =
        session.canWrite &&
        session.user?.id != null &&
        session.user?.id == competition?.ownerId;
    setPageTitle(context, context.l10n.matchNewTitle);

    return Sidebar(
      competitionName: competition?.name,
      current: null,
      canManageSettings: isOwner,
      isRegistered: session.canWrite,
      onSelectSection: _selectSection,
      onNewMatch: () {},
      onOpenHome: () => openHome(
        context,
        replace: false,
        competitionId: cubit.competitionId,
        competitionName: competition?.name,
        canManageSettings: isOwner,
      ),
      onOpenTheme: () => context.push(Routes.theme),
      onSignOut: () =>
          context.read<AuthBloc>().add(const AuthSignOutRequested()),
      child: AdaptiveScaffold(
        title: context.l10n.matchNewTitle,
        body: BlocBuilder<MatchFormCubit, MatchFormState>(
          builder: (context, state) => _body(context, state, cubit),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    MatchFormState state,
    MatchFormCubit cubit,
  ) {
    return switch (state) {
      MatchFormLoading() => const AdaptiveLoader(),
      MatchFormMissing() => EmptyState(
        message: context.l10n.competitionNotFound,
      ),
      MatchFormFailed(:final failure) => ErrorRetry(
        message: failure.localized(context.l10n),
        retryLabel: context.l10n.commonRetry,
        onRetry: cubit.load,
      ),
      MatchFormReady() => Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: _form(context, state),
      ),
    };
  }

  Widget _form(BuildContext context, MatchFormReady state) {
    final canSubmit = state.canSubmit(
      scoreAValue: _scoreAValue,
      scoreBValue: _scoreBValue,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(context.l10n.matchPickTeamsTitle, style: AppTypography.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(context.l10n.matchPickTeamsHelp, style: AppTypography.caption),
        const SizedBox(height: AppSpacing.md),

        if (state.players.isEmpty)
          EmptyState(message: context.l10n.matchNeedsPlayers)
        else
          _teamsRow(context, state),

        const SizedBox(height: AppSpacing.lg),
        Text(context.l10n.matchScoreTitle, style: AppTypography.titleSmall),
        const SizedBox(height: AppSpacing.md),
        _scoreFields(context),

        const SizedBox(height: AppSpacing.lg),

        if (_hint(state, context) case final hint?) _hintText(hint),

        AdaptiveButton(
          label: context.l10n.matchSubmit,
          busy: state.busy,
          onPressed: canSubmit ? _submit : null,
        ),

        if (state.submitFailure != null) _submitFailureText(context, state),

        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _teamsRow(BuildContext context, MatchFormReady state) {
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
          ),
        ),
      ],
    );
  }

  Widget _hintText(String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        hint,
        textAlign: TextAlign.center,
        style: AppTypography.caption,
      ),
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
                _teamMemberRow(player, ratingOf),
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
          child: Text(
            title.toUpperCase(),
            style: AppTypography.eyebrow.copyWith(color: color),
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
                fontFeatures: AppTypography.tabularFigures,
              ),
            ),
          ),
      ],
    );
  }

  Widget _teamMemberRow(
    Player player,
    double Function(String playerId) ratingOf,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              player.displayName,
              style: AppTypography.bodyMedium,
              overflow: TextOverflow.ellipsis,
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
