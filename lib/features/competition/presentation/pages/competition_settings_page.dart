import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure_messages.dart';
import '../../../../core/extensions/build_context_l10n.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/help_text.dart';
import '../../../../core/widgets/section_label.dart';
import '../../../../core/widgets/settings_switch_row.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/cubit/auth_bloc.dart';
import '../../domain/competition.dart';
import '../cubit/competition_settings_cubit.dart';

class CompetitionSettingsPage extends StatefulWidget {
  const CompetitionSettingsPage({super.key});

  @override
  State<CompetitionSettingsPage> createState() =>
      _CompetitionSettingsPageState();
}

class _CompetitionSettingsPageState extends State<CompetitionSettingsPage> {
  final _nameController = TextEditingController();
  final _kFactorController = TextEditingController();
  final _movCapController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<CompetitionSettingsCubit>().load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _kFactorController.dispose();
    _movCapController.dispose();
    super.dispose();
  }

  void _syncControllers(CompetitionSettingsState state) {
    if (_nameController.text != state.name) {
      _nameController.text = state.name;
    }
    if (_kFactorController.text != state.kFactor) {
      _kFactorController.text = state.kFactor;
    }
    if (_movCapController.text != state.movCap) {
      _movCapController.text = state.movCap;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CompetitionSettingsCubit, CompetitionSettingsState>(
      listenWhen: (previous, current) =>
          previous.competition != current.competition,
      listener: (context, state) => _syncControllers(state),
      builder: (context, state) {
        final cubit = context.read<CompetitionSettingsCubit>();
        final session = context.watch<AuthBloc>().state;

        return AdaptiveScaffold(
          title: context.l10n.competitionSettingsTitle,
          body: switch (state.status) {
            CompetitionSettingsStatus.loading => const AdaptiveLoader(),
            CompetitionSettingsStatus.missing => EmptyState(
              message: context.l10n.competitionNotFound,
            ),
            CompetitionSettingsStatus.ready
                when !state.competition!.isOwnedBy(session.user?.id) =>
              EmptyState(message: context.l10n.competitionSettingsOwnerOnly),
            CompetitionSettingsStatus.failed when state.competition == null =>
              ErrorRetry(
                message: state.failure!.localized(context.l10n),
                retryLabel: context.l10n.commonRetry,
                onRetry: cubit.load,
              ),
            _ => Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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

                  SectionLabel(context.l10n.competitionSeasonLengthLabel),
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
                  HelpText(context.l10n.competitionSeasonLengthWarning),
                  const SizedBox(height: AppSpacing.lg),

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
                    enabled: !state.busy,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    maxLength: 4,
                    errorText: state.movCap.isEmpty || state.movCapIsValid
                        ? null
                        : context.l10n.competitionMovCapInvalid,
                    onChanged: cubit.movCapChanged,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  HelpText(context.l10n.competitionMovCapHelp),
                  const SizedBox(height: AppSpacing.lg),

                  SettingsSwitchRow(
                    label: context.l10n.competitionAllowDrawsLabel,
                    help: context.l10n.competitionAllowDrawsHelp,
                    value: state.allowDraws,
                    onChanged: state.busy ? null : cubit.allowDrawsChanged,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  AdaptiveButton(
                    label: context.l10n.competitionSettingsSave,
                    busy: state.busy,
                    onPressed: state.canSubmit ? cubit.submit : null,
                  ),

                  if (state.saved)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: Text(
                        context.l10n.competitionSettingsSaved,
                        style: const TextStyle(color: AppColors.positive),
                      ),
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
              ),
            ),
          },
        );
      },
    );
  }
}
