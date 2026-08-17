import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure_messages.dart';
import '../../../../core/extensions/build_context_l10n.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/page_title.dart';
import '../../../../core/widgets/selectable_row.dart';
import '../../../player/presentation/widgets/player_name_sheet.dart';
import '../../domain/join_preview.model.dart';
import '../cubit/join_competition_cubit.dart';
import '../widgets/join_code_step.dart';

class JoinCompetitionPage extends StatelessWidget {
  const JoinCompetitionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<JoinCompetitionCubit, JoinCompetitionState>(
      listenWhen: (previous, current) =>
          current is JoinConfirm && current.joined != null,
      listener: (context, state) {
        final competitionId = (state as JoinConfirm).preview.competitionId;
        context.pop();
        context.push('/competition/$competitionId');
      },
      builder: (context, state) {
        final cubit = context.read<JoinCompetitionCubit>();
        setPageTitle(context, context.l10n.competitionsJoin);

        return AdaptiveScaffold(
          hasScrollBody: true,
          leading: state is JoinCode
              ? null
              : AdaptiveButton(
                  label: context.l10n.commonBack,
                  kind: AdaptiveButtonKind.plain,
                  expand: false,
                  onPressed: cubit.back,
                ),
          body: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: switch (state) {
              JoinCode() => const JoinCodeStep(),
              JoinConfirm() => _confirmStep(context),
            },
          ),
        );
      },
    );
  }

  Widget _confirmStep(BuildContext context) {
    final cubit = context.read<JoinCompetitionCubit>();
    final state = context.watch<JoinCompetitionCubit>().state as JoinConfirm;
    final preview = state.preview;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.joinConfirmTitle(preview.name),
          style: AppTypography.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          [
            if (preview.ownerName != null)
              context.l10n.joinRunBy(preview.ownerName!),
            context.l10n.competitionPlayers(preview.playerCount),
          ].join(' · '),
          style: const TextStyle(color: AppColors.neutral),
        ),
        const SizedBox(height: AppSpacing.xl),

        if (preview.alreadyMember)
          ..._alreadyMemberContent(context, preview.competitionId)
        else
          ..._joinFormContent(context, cubit, state, preview),

        if (state.failure != null) _failureText(context, state),
      ],
    );
  }

  List<Widget> _alreadyMemberContent(
    BuildContext context,
    String competitionId,
  ) {
    return [
      Text(context.l10n.joinAlreadyMember),
      const SizedBox(height: AppSpacing.md),
      AdaptiveButton(
        label: context.l10n.joinViewCompetition,
        onPressed: () => _viewCompetition(context, competitionId),
      ),
    ];
  }

  List<Widget> _joinFormContent(
    BuildContext context,
    JoinCompetitionCubit cubit,
    JoinConfirm state,
    JoinPreview preview,
  ) {
    return [
      if (preview.claimable.isNotEmpty)
        ..._claimListContent(context, cubit, state, preview),
      AdaptiveButton(
        label: state.selectedClaimId == null
            ? context.l10n.joinAsNewPlayer
            : context.l10n.joinConfirm,
        busy: state.busy,
        onPressed: state.canJoin ? () => _join(context, cubit, state) : null,
      ),
    ];
  }

  List<Widget> _claimListContent(
    BuildContext context,
    JoinCompetitionCubit cubit,
    JoinConfirm state,
    JoinPreview preview,
  ) {
    return [
      Text(
        context.l10n.joinClaimTitle,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(context.l10n.joinClaimSubtitle, style: AppTypography.caption),
      const SizedBox(height: AppSpacing.md),
      Expanded(
        child: ListView.separated(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          itemCount: preview.claimable.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final candidate = preview.claimable[index];
            return SelectableRow(
              label: candidate.displayName,
              selected: state.selectedClaimId == candidate.id,
              onTap: () => cubit.claimSelected(candidate.id),
            );
          },
        ),
      ),
      const SizedBox(height: AppSpacing.md),
    ];
  }

  Widget _failureText(BuildContext context, JoinConfirm state) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Text(
        state.failure!.localized(context.l10n),
        style: const TextStyle(color: AppColors.negative),
      ),
    );
  }

  Future<void> _join(
    BuildContext context,
    JoinCompetitionCubit cubit,
    JoinConfirm state,
  ) async {
    if (state.selectedClaimId != null) {
      await cubit.join();
      return;
    }

    final name = await showPlayerNameSheet(
      context,
      title: context.l10n.joinNewPlayerNameTitle,
      submitLabel: context.l10n.joinConfirm,
    );
    if (name == null) return;
    if (!context.mounted) return;
    await cubit.join(displayName: name);
  }

  void _viewCompetition(BuildContext context, String competitionId) {
    context.pop();
    context.push('/competition/$competitionId');
  }
}
