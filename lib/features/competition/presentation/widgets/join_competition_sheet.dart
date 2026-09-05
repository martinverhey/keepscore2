import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/dependency_injection/injector.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/failure_messages.dart';
import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/selectable_row.dart';
import '../../../../core/widgets/sheet.dart';
import '../../../player/presentation/widgets/player_name_sheet.dart';
import '../cubit/join_competition_cubit.dart';

Future<String?> showJoinCompetitionSheet(BuildContext context, {String? code}) {
  return showAdaptiveSheet<String>(
    context,
    builder: (_) => BlocProvider(
      create: (_) {
        final cubit = getIt<JoinCompetitionCubit>();
        if (code != null) cubit.lookUpCode(code);
        return cubit;
      },
      child: JoinCompetitionSheet(code: code),
    ),
  );
}

class JoinCompetitionSheet extends StatefulWidget {
  const JoinCompetitionSheet({super.key, this.code});

  final String? code;

  @override
  State<JoinCompetitionSheet> createState() => _JoinCompetitionSheetState();
}

class _JoinCompetitionSheetState extends State<JoinCompetitionSheet> {
  late final _code = TextEditingController(text: widget.code ?? '');

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<JoinCompetitionCubit, JoinCompetitionState>(
      listenWhen: (previous, current) =>
          current is JoinConfirm && current.joined != null,
      listener: (context, state) =>
          _close(context, (state as JoinConfirm).preview.competitionId),
      builder: (context, state) => switch (state) {
        JoinCode code => _codeSheet(context, code),
        JoinConfirm confirm => _confirmSheet(context, confirm),
      },
    );
  }

  Widget _codeSheet(BuildContext context, JoinCode state) {
    final cubit = context.read<JoinCompetitionCubit>();

    return Sheet(
      title: context.l10n.joinTitle,
      subtitle: context.l10n.joinSubtitle,
      content: _codeContent(context, state, cubit),
      primaryButton: AdaptiveButton(
        label: context.l10n.joinLookUp,
        busy: state.busy,
        onPressed: state.canLookUp ? cubit.lookUp : null,
      ),
      secondaryButton: AdaptiveButton(
        label: context.l10n.commonCancel,
        kind: AdaptiveButtonKind.plain,
        onPressed: () => _close(context, null),
      ),
    );
  }

  Widget _codeContent(
    BuildContext context,
    JoinCode state,
    JoinCompetitionCubit cubit,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AdaptiveTextField(
          label: context.l10n.competitionJoinCodeLabel,
          controller: _code,
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
              : context.l10n.joinCodeInvalid,
          onChanged: cubit.codeChanged,
          onSubmitted: (_) => cubit.lookUp(),
        ),
        ?_failureText(context, state.failure),
      ],
    );
  }

  Widget _confirmSheet(BuildContext context, JoinConfirm state) {
    final preview = state.preview;

    return Sheet(
      title: preview.name,
      subtitle: [
        if (preview.ownerName != null)
          context.l10n.joinRunBy(preview.ownerName!),
        context.l10n.competitionPlayers(preview.playerCount),
      ].join(' · '),
      content: _confirmContent(context, state),
      primaryButton: preview.alreadyMember
          ? AdaptiveButton(
              label: context.l10n.joinViewCompetition,
              onPressed: () => _close(context, preview.competitionId),
            )
          : AdaptiveButton(
              label: state.selectedClaimId == null
                  ? context.l10n.joinAsNewPlayer
                  : context.l10n.joinConfirm,
              busy: state.busy,
              onPressed: state.canJoin ? () => _join(context, state) : null,
            ),
      secondaryButton: AdaptiveButton(
        label: context.l10n.commonBack,
        kind: AdaptiveButtonKind.plain,
        onPressed: context.read<JoinCompetitionCubit>().back,
      ),
    );
  }

  Widget _confirmContent(BuildContext context, JoinConfirm state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (state.preview.alreadyMember)
          Text(context.l10n.joinAlreadyMember)
        else if (state.preview.claimable.isNotEmpty)
          ..._claimList(context, state),
        ?_failureText(context, state.failure),
      ],
    );
  }

  List<Widget> _claimList(BuildContext context, JoinConfirm state) {
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

  Widget? _failureText(BuildContext context, Failure? failure) {
    if (failure == null) return null;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Text(
        failure.localized(context.l10n),
        style: const TextStyle(color: AppColors.negative),
      ),
    );
  }

  Future<void> _join(BuildContext context, JoinConfirm state) async {
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

  void _close(BuildContext context, String? competitionId) {
    Navigator.of(context).pop(competitionId);
  }
}
