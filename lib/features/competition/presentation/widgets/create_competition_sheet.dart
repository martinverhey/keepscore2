import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/dependency_injection/injector.dart';
import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/failure_text.dart';
import '../../../../core/widgets/sheet.dart';
import '../../domain/competition.model.dart';
import '../cubit/create_competition_cubit.dart';

Future<String?> showCreateCompetitionSheet(BuildContext context) {
  return showAdaptiveSheet<String>(
    context,
    builder: (_) => BlocProvider(
      create: (_) => getIt<CreateCompetitionCubit>(),
      child: const CreateCompetitionSheet(),
    ),
  );
}

class CreateCompetitionSheet extends StatefulWidget {
  const CreateCompetitionSheet({super.key});

  @override
  State<CreateCompetitionSheet> createState() => _CreateCompetitionSheetState();
}

class _CreateCompetitionSheetState extends State<CreateCompetitionSheet> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CreateCompetitionCubit, CreateCompetitionState>(
      listenWhen: (previous, current) => current is CreateCompetitionCreated,
      listener: (context, state) =>
          _close(context, (state as CreateCompetitionCreated).competition.id),
      builder: (context, state) => switch (state) {
        CreateCompetitionEditing editing => _editingSheet(context, editing),
        CreateCompetitionCreated() => const Sheet(content: AdaptiveLoader()),
      },
    );
  }

  Widget _editingSheet(BuildContext context, CreateCompetitionEditing state) {
    final cubit = context.read<CreateCompetitionCubit>();

    return Sheet(
      title: context.l10n.competitionsCreate,
      content: _content(context, state, cubit),
      primaryButton: AdaptiveButton(
        label: context.l10n.competitionsCreateShort,
        busy: state.busy,
        onPressed: state.canSubmit ? cubit.submit : null,
      ),
      secondaryButton: AdaptiveButton(
        label: context.l10n.commonCancel,
        kind: AdaptiveButtonKind.plain,
        onPressed: () => _close(context, null),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    CreateCompetitionEditing state,
    CreateCompetitionCubit cubit,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AdaptiveTextField(
          label: context.l10n.competitionNameLabel,
          controller: _name,
          autofocus: true,
          enabled: !state.busy,
          maxLength: 60,
          textInputAction: TextInputAction.done,
          errorText: state.name.isEmpty || state.nameIsValid
              ? null
              : context.l10n.competitionNameTooShort,
          onChanged: cubit.nameChanged,
          onSubmitted: (_) => cubit.submit(),
        ),
        const SizedBox(height: AppSpacing.lg),

        Text(
          context.l10n.competitionSeasonLengthLabel,
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        AdaptiveSegmented<SeasonLength>(
          value: state.seasonLength,
          onChanged: cubit.seasonLengthChanged,
          segments: {
            SeasonLength.monthly: context.l10n.seasonMonthly,
            SeasonLength.quarterly: context.l10n.seasonQuarterly,
            SeasonLength.yearly: context.l10n.seasonYearly,
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          context.l10n.competitionSeasonExplainer(1000),
          style: AppTypography.caption,
        ),
        if (state.failure case final failure?) FailureText(failure),
      ],
    );
  }

  void _close(BuildContext context, String? competitionId) {
    Navigator.of(context).pop(competitionId);
  }
}
