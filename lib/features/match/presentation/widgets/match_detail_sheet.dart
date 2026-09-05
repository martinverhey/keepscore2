import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../app/dependency_injection/injector.dart';
import '../../../../core/error/failure_messages.dart';
import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/extensions/match_team.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/failure_text.dart';
import '../../../../core/widgets/sheet.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/titled_card.dart';
import '../../../auth/presentation/cubit/auth_bloc.dart';
import '../../domain/elo_calculator.dart';
import '../../domain/match_entry.model.dart';
import '../cubit/match_detail_cubit.dart';
import 'match_card.dart';
import 'match_score_sheet.dart';
import 'team_area.dart';

Future<void> showMatchDetailSheet(
  BuildContext context, {
  required String competitionId,
  required String matchId,
  String? myPlayerId,
}) {
  return showAdaptiveSheet<void>(
    context,
    builder: (_) => BlocProvider(
      create: (_) =>
          getIt<MatchDetailCubit>(param1: matchId, param2: competitionId)
            ..load(),
      child: MatchDetailSheet(myPlayerId: myPlayerId),
    ),
  );
}

class MatchDetailSheet extends StatelessWidget {
  const MatchDetailSheet({super.key, this.myPlayerId});

  final String? myPlayerId;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthBloc>().state;

    return BlocBuilder<MatchDetailCubit, MatchDetailState>(
      builder: (context, state) {
        final manageable = _manageableBy(state, session);

        return Sheet(
          title: context.l10n.matchDetailTitle,
          subtitle: switch (state) {
            MatchDetailReady(:final match) when match.isDraw =>
              context.l10n.matchDraw,
            _ => null,
          },
          content: _content(context, state),
          primaryButton: manageable == null
              ? null
              : _editScoreButton(context, manageable),
          secondaryButton: manageable == null
              ? null
              : _deleteButton(context, manageable),
        );
      },
    );
  }

  Widget _content(BuildContext context, MatchDetailState state) {
    final cubit = context.read<MatchDetailCubit>();

    return switch (state) {
      MatchDetailLoading() => const Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: AdaptiveLoader(),
      ),
      MatchDetailMissing() => EmptyState(message: context.l10n.matchNotFound),
      MatchDetailFailed(:final failure) => ErrorRetry(
        message: failure.localized(context.l10n),
        retryLabel: context.l10n.commonRetry,
        onRetry: cubit.load,
      ),
      MatchDetailReady() => _ready(context, state),
    };
  }

  Widget _ready(BuildContext context, MatchDetailReady state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        MatchCard(match: state.match, myPlayerId: myPlayerId),
        const SizedBox(height: AppSpacing.sm),
        _teamAreas(context, state.match),
        const SizedBox(height: AppSpacing.md),
        _winChanceCard(context, state.match),
        const SizedBox(height: AppSpacing.md),
        _addedByText(context, state),
        if (state.actionFailure case final failure?)
          FailureText(failure, textAlign: TextAlign.center),
      ],
    );
  }

  Widget _teamAreas(BuildContext context, MatchEntry match) {
    return _sides(
      teamA: _teamArea(context, match, MatchTeam.a),
      teamB: _teamArea(context, match, MatchTeam.b),
    );
  }

  Widget _teamArea(BuildContext context, MatchEntry match, MatchTeam team) {
    return TeamArea(
      title: team.label(context, isOneVsOne: match.isOneVsOne),
      color: _teamColor(context, team),
      members: _members(match, team),
      rating: team == MatchTeam.a ? match.teamARating : match.teamBRating,
      myPlayerId: myPlayerId,
    );
  }

  Widget _winChanceCard(BuildContext context, MatchEntry match) {
    return TitledCard(child: _winChanceThirds(context, match));
  }

  Widget _winChanceThirds(BuildContext context, MatchEntry match) {
    return Row(
      children: [
        Expanded(child: _winChanceValue(context, match, MatchTeam.a)),
        Expanded(child: _winChanceTitle(context)),
        Expanded(child: _winChanceValue(context, match, MatchTeam.b)),
      ],
    );
  }

  Widget _winChanceValue(
    BuildContext context,
    MatchEntry match,
    MatchTeam team,
  ) {
    return Text(
      _percentLabel(context, _winChanceOf(match, team)),
      textAlign: TextAlign.center,
      style: AppTypography.headlineMedium.copyWith(
        fontFeatures: AppTypography.tabularFigures,
        color: _teamColor(context, team),
      ),
    );
  }

  Widget _winChanceTitle(BuildContext context) {
    return Text(
      context.l10n.matchWinChanceTitle,
      textAlign: TextAlign.center,
      style: AppTypography.titleSmall,
    );
  }

  Widget _addedByText(BuildContext context, MatchDetailReady state) {
    return Text(
      context.l10n.matchAddedBy(
        state.createdByName ?? context.l10n.matchAddedByUnknown,
        _playedAtLabel(context, state.match),
      ),
      textAlign: TextAlign.center,
      style: AppTypography.caption,
    );
  }

  Widget _sides({required Widget teamA, required Widget teamB}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: teamA),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: teamB),
      ],
    );
  }

  AdaptiveButton _editScoreButton(
    BuildContext context,
    MatchDetailReady state,
  ) {
    return AdaptiveButton(
      label: context.l10n.matchEditScore,
      kind: AdaptiveButtonKind.tinted,
      busy: state.busy,
      onPressed: () => _editScore(context, state.match),
    );
  }

  AdaptiveButton _deleteButton(BuildContext context, MatchDetailReady state) {
    return AdaptiveButton(
      label: context.l10n.matchDelete,
      kind: AdaptiveButtonKind.destructive,
      onPressed: state.busy ? null : () => _delete(context),
    );
  }

  Future<void> _editScore(BuildContext context, MatchEntry match) async {
    final cubit = context.read<MatchDetailCubit>();

    final scores = await showAdaptiveSheet<(int, int)>(
      context,
      builder: (_) => MatchScoreSheet(match: match),
    );
    if (scores == null) return;

    await cubit.updateScore(scoreA: scores.$1, scoreB: scores.$2);
  }

  Future<void> _delete(BuildContext context) async {
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
    if (deleted && context.mounted) Navigator.of(context).pop();
  }
}

MatchDetailReady? _manageableBy(
  MatchDetailState state,
  AuthSessionState session,
) => switch (state) {
  MatchDetailReady ready
      when session.canWrite && ready.isManageableBy(session.user?.id) =>
    ready,
  _ => null,
};

String _playedAtLabel(BuildContext context, MatchEntry match) =>
    DateFormat.yMMMd(context.languageTag).add_Hm().format(match.playedAt);

List<TeamAreaMember> _members(MatchEntry match, MatchTeam team) => match
    .players(team)
    .map(
      (participant) => TeamAreaMember(
        id: participant.playerId,
        displayName: participant.displayName,
        rating: participant.ratingBefore,
      ),
    )
    .toList(growable: false);

double _winChanceOf(MatchEntry match, MatchTeam team) =>
    EloCalculator.winChance(
      ratingA: team == MatchTeam.a ? match.teamARating : match.teamBRating,
      ratingB: team == MatchTeam.a ? match.teamBRating : match.teamARating,
    );

String _percentLabel(BuildContext context, double chance) =>
    NumberFormat.percentPattern(context.languageTag).format(chance);

Color _teamColor(BuildContext context, MatchTeam team) => team == MatchTeam.a
    ? AdaptiveColors.teamA(context)
    : AdaptiveColors.teamB(context);
