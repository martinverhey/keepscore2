import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure_messages.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../player/presentation/widgets/player_name_sheet.dart';
import '../cubit/join_competition_cubit.dart';

class JoinCompetitionPage extends StatelessWidget {
  const JoinCompetitionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocConsumer<JoinCompetitionCubit, JoinCompetitionState>(
      listenWhen: (previous, current) => current.joined != null,
      listener: (context, state) {
        final competitionId = state.preview!.competitionId;
        context.pop();
        context.push('/competition/$competitionId');
      },
      builder: (context, state) {
        final cubit = context.read<JoinCompetitionCubit>();

        return AdaptiveScaffold(
          title: l10n.joinTitle,
          leading: state.step == JoinStep.code
              ? null
              : AdaptiveButton(
                  label: l10n.commonBack,
                  kind: AdaptiveButtonKind.plain,
                  expand: false,
                  onPressed: cubit.back,
                ),
          body: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: switch (state.step) {
              JoinStep.code => const _CodeStep(),
              JoinStep.confirm => const _ConfirmStep(),
            },
          ),
        );
      },
    );
  }
}

class _CodeStep extends StatefulWidget {
  const _CodeStep();

  @override
  State<_CodeStep> createState() => _CodeStepState();
}

class _CodeStepState extends State<_CodeStep> {
  late final TextEditingController _controller = TextEditingController(
    text: context.read<JoinCompetitionCubit>().state.code,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<JoinCompetitionCubit>();
    final state = context.watch<JoinCompetitionCubit>().state;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.joinSubtitle,
          style: const TextStyle(color: AppColors.neutral),
        ),
        const SizedBox(height: AppSpacing.lg),
        AdaptiveTextField(
          label: l10n.competitionJoinCodeLabel,
          controller: _controller,
          autofocus: true,
          enabled: !state.busy,
          maxLength: 8,
          textInputAction: TextInputAction.done,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Za-z\s-]')),
            TextInputFormatter.withFunction(
              (_, next) => next.copyWith(text: next.text.toUpperCase()),
            ),
          ],
          errorText: state.code.isEmpty || state.codeIsValid
              ? null
              : l10n.joinCodeInvalid,
          onChanged: cubit.codeChanged,
          onSubmitted: (_) => cubit.lookUp(),
        ),
        const SizedBox(height: AppSpacing.lg),
        AdaptiveButton(
          label: l10n.joinLookUp,
          busy: state.busy,
          onPressed: state.canLookUp ? cubit.lookUp : null,
        ),
        if (state.failure != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Text(
              state.failure!.localized(l10n),
              style: const TextStyle(color: AppColors.negative),
            ),
          ),
      ],
    );
  }
}

class _ConfirmStep extends StatelessWidget {
  const _ConfirmStep();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<JoinCompetitionCubit>();
    final state = context.watch<JoinCompetitionCubit>().state;
    final preview = state.preview!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.joinConfirmTitle(preview.name),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          [
            if (preview.ownerName != null) l10n.joinRunBy(preview.ownerName!),
            l10n.competitionPlayers(preview.playerCount),
          ].join(' · '),
          style: const TextStyle(color: AppColors.neutral),
        ),
        const SizedBox(height: AppSpacing.xl),

        if (preview.alreadyMember)
          Text(l10n.joinAlreadyMember)
        else ...[
          if (preview.claimable.isNotEmpty) ...[
            Text(
              l10n.joinClaimTitle,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.joinClaimSubtitle,
              style: const TextStyle(color: AppColors.neutral, fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final candidate in preview.claimable) ...[
              _ClaimOption(
                label: candidate.displayName,
                selected: state.selectedClaimId == candidate.id,
                onTap: () => cubit.claimSelected(candidate.id),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            const SizedBox(height: AppSpacing.md),
          ],

          AdaptiveButton(
            label: state.selectedClaimId == null
                ? l10n.joinAsNewPlayer
                : l10n.joinConfirm,
            busy: state.busy,
            onPressed: state.canJoin
                ? () => _join(context, cubit, state)
                : null,
          ),
        ],

        if (state.failure != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Text(
              state.failure!.localized(l10n),
              style: const TextStyle(color: AppColors.negative),
            ),
          ),
      ],
    );
  }

  Future<void> _join(
    BuildContext context,
    JoinCompetitionCubit cubit,
    JoinCompetitionState state,
  ) async {
    if (state.selectedClaimId != null) {
      await cubit.join();
      return;
    }

    final l10n = AppLocalizations.of(context);
    final name = await showPlayerNameSheet(
      context,
      title: l10n.joinNewPlayerNameTitle,
      submitLabel: l10n.joinConfirm,
    );
    if (name == null) return;
    if (!context.mounted) return;
    await cubit.join(displayName: name);
  }
}

class _ClaimOption extends StatelessWidget {
  const _ClaimOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: AppRadius.card,
          color: selected
              ? AdaptiveColors.accent(context).withValues(alpha: 0.16)
              : AppColors.neutral.withValues(alpha: 0.08),
          border: Border.all(
            color: selected
                ? AdaptiveColors.accent(context)
                : const Color(0x00000000),
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            color: selected ? AdaptiveColors.accent(context) : null,
          ),
        ),
      ),
    );
  }
}
