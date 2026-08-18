import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/error/failure_messages.dart';
import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/help_text.dart';
import '../../../../core/widgets/page_title.dart';
import '../../../../core/widgets/section_label.dart';
import '../../../../core/widgets/settings_switch_row.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/cubit/auth_bloc.dart';
import '../../../competition/domain/competition.model.dart';
import '../../../competition/presentation/cubit/competition_cubit.dart';
import '../../../competition/presentation/widgets/competition_section.enum.dart';
import '../../../competition/presentation/widgets/home_sidebar_competition.dart';
import '../../../competition/presentation/widgets/open_home.dart';
import '../../../competition/presentation/widgets/open_theme.dart';
import '../../../competition/presentation/widgets/select_competition_section.dart';
import '../../../competition/presentation/widgets/sidebar.dart';
import '../cubit/configuration_cubit.dart';

class ConfigurationPage extends StatefulWidget {
  const ConfigurationPage({super.key});

  @override
  State<ConfigurationPage> createState() => _ConfigurationPageState();
}

class _ConfigurationPageState extends State<ConfigurationPage> {
  final _nameController = TextEditingController();
  final _kFactorController = TextEditingController();
  final _movCapController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ConfigurationCubit>().load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _kFactorController.dispose();
    _movCapController.dispose();
    super.dispose();
  }

  void _syncControllers(ConfigurationReady state) {
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

  void _selectSection(CompetitionSection section) => selectCompetitionSection(
    context,
    competitionId: context.read<ConfigurationCubit>().competitionId,
    current: CompetitionSection.configuration,
    target: section,
  );

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ConfigurationCubit, ConfigurationState>(
      listenWhen: (previous, current) =>
          current is ConfigurationReady &&
          (previous is! ConfigurationReady ||
              previous.competition != current.competition),
      listener: (context, state) =>
          _syncControllers(state as ConfigurationReady),
      builder: (context, state) => _sidebar(context, state),
    );
  }

  Widget _sidebar(BuildContext context, ConfigurationState state) {
    final cubit = context.read<ConfigurationCubit>();
    final session = context.watch<AuthBloc>().state;
    final competitionDetail = context
        .watch<CompetitionCubit>()
        .state
        .competition;
    setPageTitle(context, context.l10n.configurationTitle);

    final isOwner =
        session.canWrite &&
        session.user?.id != null &&
        session.user?.id == competitionDetail?.ownerId;

    return Sidebar(
      competitionName: competitionDetail?.name,
      current: CompetitionSection.configuration,
      canManageSettings: isOwner,
      isRegistered: session.canWrite,
      onSelectSection: _selectSection,
      onNewMatch: () =>
          context.push<Object?>(Routes.newMatch(cubit.competitionId)),
      onOpenHome: () => openHome(
        context,
        replace: true,
        competitionId: cubit.competitionId,
        competitionName: competitionDetail?.name,
        canManageSettings: isOwner,
      ),
      onOpenTheme: () => openTheme(
        context,
        replace: true,
        sidebarCompetition: HomeSidebarCompetition(
          competitionId: cubit.competitionId,
          competitionName: competitionDetail?.name,
          canManageSettings: isOwner,
        ),
      ),
      onSignOut: () =>
          context.read<AuthBloc>().add(const AuthSignOutRequested()),
      child: AdaptiveScaffold(
        title: context.l10n.configurationTitle,
        body: _body(context, state, cubit: cubit, session: session),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    ConfigurationState state, {
    required ConfigurationCubit cubit,
    required AuthSessionState session,
  }) {
    return switch (state) {
      ConfigurationLoading() => const AdaptiveLoader(),
      ConfigurationMissing() => EmptyState(
        message: context.l10n.competitionNotFound,
      ),
      ConfigurationReady()
          when !state.competition.isOwnedBy(session.user?.id) =>
        EmptyState(message: context.l10n.configurationOwnerOnly),
      ConfigurationFailed(:final failure) => ErrorRetry(
        message: failure.localized(context.l10n),
        retryLabel: context.l10n.commonRetry,
        onRetry: cubit.load,
      ),
      ConfigurationReady() => _form(context, state, cubit),
    };
  }

  Widget _form(
    BuildContext context,
    ConfigurationReady state,
    ConfigurationCubit cubit,
  ) {
    return Padding(
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
            label: context.l10n.configurationSave,
            busy: state.busy,
            onPressed: state.canSubmit ? cubit.submit : null,
          ),

          if (state.saved)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Text(
                context.l10n.configurationSaved,
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
    );
  }
}
