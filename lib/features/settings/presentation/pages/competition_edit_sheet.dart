import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/dependency_injection/injector.dart';
import '../../../../core/error/failure_messages.dart';
import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/disclosure_row.dart';
import '../../../../core/widgets/failure_text.dart';
import '../../../../core/widgets/help_text.dart';
import '../../../../core/widgets/settings_switch_row.dart';
import '../../../../core/widgets/sheet.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../competition/domain/competition.model.dart';
import '../cubit/competition_edit_cubit.dart';

Future<bool> showCompetitionEditSheet(
  BuildContext context, {
  required String competitionId,
}) async {
  final saved = await showAdaptiveSheet<bool>(
    context,
    builder: (_) => BlocProvider(
      create: (_) => getIt<CompetitionEditCubit>(param1: competitionId)..load(),
      child: const CompetitionEditSheet(),
    ),
  );
  return saved ?? false;
}

class CompetitionEditSheet extends StatefulWidget {
  const CompetitionEditSheet({super.key});

  @override
  State<CompetitionEditSheet> createState() => _CompetitionEditSheetState();
}

class _CompetitionEditSheetState extends State<CompetitionEditSheet> {
  final _nameController = TextEditingController();
  final _kFactorController = TextEditingController();
  final _movCapController = TextEditingController();
  final _shutoutMultiplierController = TextEditingController();
  var _showsAdvanced = false;

  @override
  void dispose() {
    _nameController.dispose();
    _kFactorController.dispose();
    _movCapController.dispose();
    _shutoutMultiplierController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CompetitionEditCubit, CompetitionEditState>(
      listenWhen: (previous, current) =>
          current is CompetitionEditSaved ||
          (current is CompetitionEditReady &&
              (previous is! CompetitionEditReady ||
                  previous.competition != current.competition)),
      listener: _onState,
      builder: (context, state) => Sheet(
        title: context.l10n.competitionEdit,
        content: _content(context, state),
        primaryButton: _saveButton(context, state),
      ),
    );
  }

  void _onState(BuildContext context, CompetitionEditState state) {
    switch (state) {
      case CompetitionEditSaved():
        Navigator.of(context).pop(true);
      case CompetitionEditReady():
        _syncControllers(state);
      default:
    }
  }

  void _syncControllers(CompetitionEditReady state) {
    if (_nameController.text != state.name) {
      _nameController.text = state.name;
    }
    if (_kFactorController.text != state.kFactor) {
      _kFactorController.text = state.kFactor;
    }
    if (_movCapController.text != state.movCap) {
      _movCapController.text = state.movCap;
    }
    if (_shutoutMultiplierController.text != state.shutoutMultiplier) {
      _shutoutMultiplierController.text = state.shutoutMultiplier;
    }
  }

  Widget _content(BuildContext context, CompetitionEditState state) {
    final cubit = context.read<CompetitionEditCubit>();
    final session = context.watch<AuthCubit>().state;

    return switch (state) {
      CompetitionEditLoading() ||
      CompetitionEditSaved() => const AdaptiveLoader(),
      CompetitionEditMissing() => EmptyState(
        message: context.l10n.competitionNotFound,
      ),
      CompetitionEditFailed(:final failure) => ErrorRetry(
        message: failure.localized(context.l10n),
        retryLabel: context.l10n.commonRetry,
        onRetry: cubit.load,
      ),
      CompetitionEditReady()
          when !state.competition.isOwnedBy(session.user?.id) =>
        EmptyState(message: context.l10n.competitionEditOwnerOnly),
      CompetitionEditReady() => _form(context, state, cubit),
    };
  }

  Widget? _saveButton(BuildContext context, CompetitionEditState state) {
    if (state is! CompetitionEditReady) return null;
    final session = context.watch<AuthCubit>().state;
    if (!state.competition.isOwnedBy(session.user?.id)) return null;
    final cubit = context.read<CompetitionEditCubit>();

    return AdaptiveButton(
      label: context.l10n.competitionEditSave,
      busy: state.busy,
      onPressed: state.canSubmit ? cubit.submit : null,
    );
  }

  Widget _form(
    BuildContext context,
    CompetitionEditReady state,
    CompetitionEditCubit cubit,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AdaptiveTextField(
          label: context.l10n.competitionNameLabel,
          controller: _nameController,
          enabled: !state.busy,
          maxLength: 60,
          errorText: state.name.isEmpty || state.nameIsValid
              ? null
              : context.l10n.competitionNameTooShort,
          onChanged: cubit.nameChanged,
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
          context.l10n.competitionSeasonLengthWarning,
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
    CompetitionEditReady state,
    CompetitionEditCubit cubit,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: AppSpacing.sm),
        AdaptiveTextField(
          label: context.l10n.competitionKFactorLabel,
          controller: _kFactorController,
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
          controller: _movCapController,
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
          controller: _shutoutMultiplierController,
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
}
