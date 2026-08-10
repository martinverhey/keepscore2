import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/error/failure_messages.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/rating_delta.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/match_entry.dart';
import '../bloc/match_detail_cubit.dart';

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
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<MatchDetailCubit>();

    final confirmed = await showAdaptiveConfirm(
      context,
      title: l10n.matchDeleteTitle,
      message: l10n.matchDeleteConfirm,
      confirmLabel: l10n.commonDelete,
      cancelLabel: l10n.commonCancel,
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
      builder: (_) => _ScoreSheet(match: match),
    );
    if (scores == null) return;

    await cubit.updateScore(scoreA: scores.$1, scoreB: scores.$2);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = context.watch<AuthBloc>().state;
    final cubit = context.read<MatchDetailCubit>();

    return BlocBuilder<MatchDetailCubit, MatchDetailState>(
      builder: (context, state) {
        final match = state.match;
        final canManage =
            session.canWrite && state.isManageableBy(session.user?.id);

        return AdaptiveScaffold(
          title: l10n.matchDetailTitle,
          body: switch (state.status) {
            MatchDetailStatus.loading => const AdaptiveLoader(),
            MatchDetailStatus.missing => EmptyState(message: l10n.matchNotFound),
            MatchDetailStatus.failed => ErrorRetry(
              message: state.failure!.localized(l10n),
              retryLabel: l10n.commonRetry,
              onRetry: cubit.load,
            ),
            MatchDetailStatus.ready => SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Scoreline(match: match!),
                  const SizedBox(height: AppSpacing.lg),
                  _TeamCard(
                    title: l10n.matchTeamA,
                    color: AdaptiveColors.teamA(context),
                    match: match,
                    team: MatchTeam.a,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _TeamCard(
                    title: l10n.matchTeamB,
                    color: AdaptiveColors.teamB(context),
                    match: match,
                    team: MatchTeam.b,
                  ),

                  if (canManage) ...[
                    const SizedBox(height: AppSpacing.xl),
                    AdaptiveButton(
                      label: l10n.matchEditScore,
                      kind: AdaptiveButtonKind.tinted,
                      busy: state.busy,
                      onPressed: () => _editScore(match),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AdaptiveButton(
                      label: l10n.matchDelete,
                      kind: AdaptiveButtonKind.destructive,
                      onPressed: state.busy ? null : _delete,
                    ),
                  ],

                  if (state.actionFailure != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: Text(
                        state.actionFailure!.localized(l10n),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.negative),
                      ),
                    ),

                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          },
        );
      },
    );
  }
}

class _Scoreline extends StatelessWidget {
  const _Scoreline({required this.match});

  final MatchEntry match;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();

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
            l10n.matchDraw,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        Text(
          DateFormat.yMMMd(locale).add_Hm().format(match.playedAt),
          style: const TextStyle(color: AppColors.neutral, fontSize: 13),
        ),
      ],
    );
  }
}

class _TeamCard extends StatelessWidget {
  const _TeamCard({
    required this.title,
    required this.color,
    required this.match,
    required this.team,
  });

  final String title;
  final Color color;
  final MatchEntry match;
  final MatchTeam team;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
              Text(
                l10n.matchTeamRating(
                  formatRating(
                    team == MatchTeam.a ? match.teamARating : match.teamBRating,
                  ),
                ),
                style: const TextStyle(color: AppColors.neutral, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final participant in roster)
            Padding(
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
            ),
        ],
      ),
    );
  }
}

class _ScoreSheet extends StatefulWidget {
  const _ScoreSheet({required this.match});

  final MatchEntry match;

  @override
  State<_ScoreSheet> createState() => _ScoreSheetState();
}

class _ScoreSheetState extends State<_ScoreSheet> {
  late final _scoreA = TextEditingController(
    text: '${widget.match.teamAScore}',
  );
  late final _scoreB = TextEditingController(
    text: '${widget.match.teamBScore}',
  );

  @override
  void dispose() {
    _scoreA.dispose();
    _scoreB.dispose();
    super.dispose();
  }

  int? get _a => int.tryParse(_scoreA.text.trim());

  int? get _b => int.tryParse(_scoreB.text.trim());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final valid = _a != null && _b != null;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.matchEditScoreTitle,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.matchEditScoreHelp,
            style: const TextStyle(color: AppColors.neutral, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AdaptiveTextField(
                  label: l10n.matchScoreTeam(l10n.matchTeamA),
                  controller: _scoreA,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 3,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AdaptiveTextField(
                  label: l10n.matchScoreTeam(l10n.matchTeamB),
                  controller: _scoreB,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 3,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AdaptiveButton(
            label: l10n.commonSave,
            onPressed: valid
                ? () => Navigator.of(context).pop((_a!, _b!))
                : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          AdaptiveButton(
            label: l10n.commonCancel,
            kind: AdaptiveButtonKind.plain,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
