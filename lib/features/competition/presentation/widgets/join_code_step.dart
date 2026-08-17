import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure_messages.dart';
import '../../../../core/extensions/build_context_l10n.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../cubit/join_competition_cubit.dart';

class JoinCodeStep extends StatefulWidget {
  const JoinCodeStep({super.key});

  @override
  State<JoinCodeStep> createState() => _JoinCodeStepState();
}

class _JoinCodeStepState extends State<JoinCodeStep> {
  late final TextEditingController _controller = TextEditingController(
    text: (context.read<JoinCompetitionCubit>().state as JoinCode).code,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<JoinCompetitionCubit>();
    final state = context.watch<JoinCompetitionCubit>().state as JoinCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xxl),
        Text(context.l10n.joinTitle, style: AppTypography.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          context.l10n.joinSubtitle,
          style: const TextStyle(color: AppColors.neutral),
        ),
        const SizedBox(height: AppSpacing.lg),
        AdaptiveTextField(
          label: context.l10n.competitionJoinCodeLabel,
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
              : context.l10n.joinCodeInvalid,
          onChanged: cubit.codeChanged,
          onSubmitted: (_) => cubit.lookUp(),
        ),
        const SizedBox(height: AppSpacing.lg),
        AdaptiveButton(
          label: context.l10n.joinLookUp,
          busy: state.busy,
          onPressed: state.canLookUp ? cubit.lookUp : null,
        ),
        if (state.failure != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Text(
              state.failure!.localized(context.l10n),
              style: const TextStyle(color: AppColors.negative),
            ),
          ),
      ],
    );
  }
}
