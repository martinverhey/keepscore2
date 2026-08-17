import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/error/failure_messages.dart';
import '../../../../core/extensions/build_context_l10n.dart';
import '../../../../core/extensions/build_context_locale.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/page_title.dart';
import '../../../../core/widgets/rating_delta.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/cubit/auth_bloc.dart';
import '../../domain/match_entry.model.dart';
import '../cubit/match_detail_cubit.dart';
import '../widgets/match_score_sheet.dart';

class MatchDetailPage extends StatefulWidget {
  const MatchDetailPage({super.key});

  @override
  State<MatchDetailPage> createState() => _MatchDetailPageState();
}

class _MatchDetailPageState extends State<MatchDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<MatchDetailCubit>().load();
  }

  Future<void> _delete() async {
    final cubit = context.read<MatchDetailCubit>();

    final confirmed = await showAdaptiveConfirm(
      context,
      title: context.l10n.matchDeleteTitle,
      message: context.l10n.matchDeleteConfirm,
      confirmLabel: context.l10n.commonDelete,
      cancelLabel: context.l10n.commonCancel,
      destructive: true,
    );
    if (!confirmed) return;

    final deleted = await cubit.delete();
    if (deleted && mounted) context.pop(true);
  }

  Future<void> _editScore(MatchEntry match) async {
    final cubit = context.read<MatchDetailCubit>();

    final scores = await showAdaptiveSheet<(int, int)>(
      context,
      builder: (_) => MatchScoreSheet(match: match),
    );
    if (scores == null) return;

    await cubit.updateScore(scoreA: scores.$1, scoreB: scores.$2);
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthBloc>().state;
    final cubit = context.read<MatchDetailCubit>();

    return BlocBuilder<MatchDetailCubit, MatchDetailState>(
      builder: (context, state) {
        setPageTitle(context, context.l10n.matchDetailTitle);
        return AdaptiveScaffold(
          title: context.l10n.matchDetailTitle,
          body: _body(context, state, session, cubit),
        );
      },
    );
  }

  Widget _body(
    BuildContext context,
    MatchDetailState state,
    AuthSessionState session,
    MatchDetailCubit cubit,
  ) {
    return switch (state.status) {
      MatchDetailStatus.loading => const AdaptiveLoader(),
      MatchDetailStatus.missing => EmptyState(
        message: context.l10n.matchNotFound,
      ),
      MatchDetailStatus.failed => ErrorRetry(
        message: state.failure!.localized(context.l10n),
        retryLabel: context.l10n.commonRetry,
        onRetry: cubit.load,
      ),
      MatchDetailStatus.ready => _ready(context, state, session),
    };
  }

  Widget _ready(
    BuildContext context,
    MatchDetailState state,
    AuthSessionState session,
  ) {
    final match = state.match!;
    final canManage =
        session.canWrite && state.isManageableBy(session.user?.id);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _scoreline(context, match),
          const SizedBox(height: AppSpacing.lg),
          _teamCard(
            context,
            title: context.l10n.matchTeamA,
            color: AdaptiveColors.teamA(context),
            match: match,
            team: MatchTeam.a,
          ),
          const SizedBox(height: AppSpacing.md),
          _teamCard(
            context,
            title: context.l10n.matchTeamB,
            color: AdaptiveColors.teamB(context),
            match: match,
            team: MatchTeam.b,
          ),
          if (canManage) _manageButtons(context, match, state),
          if (state.actionFailure != null) _actionFailureText(context, state),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _manageButtons(
    BuildContext context,
    MatchEntry match,
    MatchDetailState state,
  ) {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.xl),
        AdaptiveButton(
          label: context.l10n.matchEditScore,
          kind: AdaptiveButtonKind.tinted,
          busy: state.busy,
          onPressed: () => _editScore(match),
        ),
        const SizedBox(height: AppSpacing.sm),
        AdaptiveButton(
          label: context.l10n.matchDelete,
          kind: AdaptiveButtonKind.destructive,
          onPressed: state.busy ? null : _delete,
        ),
      ],
    );
  }

  Widget _actionFailureText(BuildContext context, MatchDetailState state) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Text(
        state.actionFailure!.localized(context.l10n),
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.negative),
      ),
    );
  }

  Widget _scoreline(BuildContext context, MatchEntry match) {
    return Column(
      children: [
        Text(
          '${match.teamAScore} – ${match.teamBScore}',
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w700,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        if (match.isDraw)
          Text(
            context.l10n.matchDraw,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        Text(
          DateFormat.yMMMd(context.languageTag).add_Hm().format(match.playedAt),
          style: const TextStyle(color: AppColors.neutral, fontSize: 13),
        ),
      ],
    );
  }

  Widget _teamCard(
    BuildContext context, {
    required String title,
    required Color color,
    required MatchEntry match,
    required MatchTeam team,
  }) {
    final roster = match.roster(team);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: AppRadius.card,
        color: AppColors.neutral.withValues(alpha: 0.08),
        border: match.winner == team
            ? Border.all(color: color.withValues(alpha: 0.6), width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _teamHeader(
            context,
            title: title,
            color: color,
            match: match,
            team: team,
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final participant in roster) _participantRow(participant),
        ],
      ),
    );
  }

  Widget _teamHeader(
    BuildContext context, {
    required String title,
    required Color color,
    required MatchEntry match,
    required MatchTeam team,
  }) {
    return Row(
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
        Text(
          context.l10n.matchTeamRating(
            formatRating(
              team == MatchTeam.a ? match.teamARating : match.teamBRating,
            ),
          ),
          style: const TextStyle(color: AppColors.neutral, fontSize: 12),
        ),
      ],
    );
  }

  Widget _participantRow(MatchParticipant participant) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              participant.displayName,
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${formatRating(participant.ratingBefore)} → '
            '${formatRating(participant.ratingAfter)}',
            style: const TextStyle(
              color: AppColors.neutral,
              fontSize: 13,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 52,
            child: Align(
              alignment: Alignment.centerRight,
              child: RatingDelta(value: participant.ratingDelta),
            ),
          ),
        ],
      ),
    );
  }
}
