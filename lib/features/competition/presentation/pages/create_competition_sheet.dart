import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/dependency_injection/injector.dart';
import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/disclosure_row.dart';
import '../../../../core/widgets/failure_text.dart';
import '../../../../core/widgets/help_text.dart';
import '../../../../core/widgets/settings_switch_row.dart';
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
  final _kFactor = TextEditingController();
  final _movCap = TextEditingController();
  final _shutoutMultiplier = TextEditingController();
  var _showsAdvanced = false;

  @override
  void initState() {
    super.initState();
    if (context.read<CreateCompetitionCubit>().state
        case CreateCompetitionEditing initial) {
      _kFactor.text = initial.kFactor;
      _movCap.text = initial.movCap;
      _shutoutMultiplier.text = initial.shutoutMultiplier;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _kFactor.dispose();
    _movCap.dispose();
    _shutoutMultiplier.dispose();
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
        const SizedBox(height: AppSpacing.md),
        DisclosureRow(
          label: context.l10n.competitionAdvancedLabel,
          expanded: _showsAdvanced,
          onTap: () => setState(() => _showsAdvanced = !_showsAdvanced),
        ),
        if (_showsAdvanced) _advanced(context, state, cubit),
        if (state.failure case final failure?) FailureText(failure),
      ],
    );
  }

  Widget _advanced(
    BuildContext context,
    CreateCompetitionEditing state,
    CreateCompetitionCubit cubit,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: AppSpacing.sm),
        AdaptiveTextField(
          label: context.l10n.competitionKFactorLabel,
          controller: _kFactor,
          enabled: !state.busy,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 3,
          errorText: state.kFactor.isEmpty || state.kFactorIsValid
              ? null
              : context.l10n.competitionKFactorInvalid,
          onChanged: cubit.kFactorChanged,
        ),
        const SizedBox(height: AppSpacing.xs),
        HelpText(context.l10n.competitionKFactorHelp),
        const SizedBox(height: AppSpacing.lg),
        SettingsSwitchRow(
          label: context.l10n.competitionMovLabel,
          help: context.l10n.competitionMovHelp,
          value: state.movEnabled,
          onChanged: state.busy ? null : cubit.movEnabledChanged,
        ),
        const SizedBox(height: AppSpacing.md),
        AdaptiveTextField(
          label: context.l10n.competitionMovCapLabel,
          controller: _movCap,
          enabled: !state.busy && state.movEnabled,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          maxLength: 4,
          errorText: state.movCap.isEmpty || state.movCapIsValid
              ? null
              : context.l10n.competitionMovCapInvalid,
          onChanged: cubit.movCapChanged,
        ),
        const SizedBox(height: AppSpacing.lg),
        SettingsSwitchRow(
          label: context.l10n.competitionShutoutBonusLabel,
          help: context.l10n.competitionShutoutBonusHelp,
          value: state.shutoutBonus,
          onChanged: state.busy || !state.movEnabled
              ? null
              : cubit.shutoutBonusChanged,
        ),
        const SizedBox(height: AppSpacing.md),
        AdaptiveTextField(
          label: context.l10n.competitionShutoutMultiplierLabel,
          controller: _shutoutMultiplier,
          enabled: !state.busy && state.movEnabled && state.shutoutBonus,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          maxLength: 4,
          errorText:
              state.shutoutMultiplier.isEmpty || state.shutoutMultiplierIsValid
              ? null
              : context.l10n.competitionShutoutMultiplierInvalid,
          onChanged: cubit.shutoutMultiplierChanged,
        ),
      ],
    );
  }

  void _close(BuildContext context, String competitionId) {
    Navigator.of(context).pop(competitionId);
  }
}
