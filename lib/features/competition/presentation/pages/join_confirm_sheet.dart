import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/failure_text.dart';
import '../../../../core/widgets/selectable_row.dart';
import '../../../../core/widgets/sheet.dart';
import '../../../player/presentation/pages/player_name_sheet.dart';
import '../cubit/join_competition_cubit.dart';
import '../widgets/join_result.dart';

class JoinConfirmSheet extends StatelessWidget {
  const JoinConfirmSheet({
    super.key,
    required this.state,
    required this.isScanned,
  });

  final JoinConfirm state;
  final bool isScanned;

  @override
  Widget build(BuildContext context) {
    final preview = state.preview;

    return Sheet(
      title: preview.name,
      subtitle: [
        if (preview.ownerName != null)
          context.l10n.joinRunBy(preview.ownerName!),
        context.l10n.competitionPlayers(preview.playerCount),
      ].join(' · '),
      content: _content(context),
      primaryButton: _primaryButton(context),
      secondaryButton: _backButton(context),
    );
  }

  Widget _content(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (state.preview.alreadyMember)
          Text(context.l10n.joinAlreadyMember)
        else if (state.preview.claimable.isNotEmpty)
          ..._claimList(context),
        if (state.failure case final failure?) FailureText(failure),
      ],
    );
  }

  List<Widget> _claimList(BuildContext context) {
    final cubit = context.read<JoinCompetitionCubit>();

    return [
      Text(
        context.l10n.joinClaimTitle,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(context.l10n.joinClaimSubtitle, style: AppTypography.caption),
      const SizedBox(height: AppSpacing.md),
      for (final candidate in state.preview.claimable)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: SelectableRow(
            label: candidate.displayName,
            selected: state.selectedClaimId == candidate.id,
            onTap: () => cubit.claimSelected(candidate.id),
          ),
        ),
    ];
  }

  Widget _primaryButton(BuildContext context) {
    if (state.preview.alreadyMember) {
      return AdaptiveButton(
        label: context.l10n.joinViewCompetition,
        onPressed: () => Navigator.of(
          context,
        ).pop(JoinResult.joined(state.preview.competitionId)),
      );
    }

    return AdaptiveButton(
      label: state.selectedClaimId == null
          ? context.l10n.joinAsNewPlayer
          : context.l10n.joinConfirm,
      busy: state.busy,
      onPressed: state.canJoin ? () => _join(context) : null,
    );
  }

  Widget _backButton(BuildContext context) {
    return AdaptiveButton(
      label: context.l10n.commonBack,
      kind: AdaptiveButtonKind.plain,
      onPressed: isScanned
          ? () => Navigator.of(context).pop(const JoinResult.back())
          : context.read<JoinCompetitionCubit>().back,
    );
  }

  Future<void> _join(BuildContext context) async {
    final cubit = context.read<JoinCompetitionCubit>();
    if (state.selectedClaimId != null) {
      await cubit.join();
      return;
    }

    final name = await showPlayerNameSheet(
      context,
      title: context.l10n.joinNewPlayerNameTitle,
      submitLabel: context.l10n.joinConfirm,
    );
    if (name == null || !context.mounted) return;

    await cubit.join(displayName: name);
  }
}
