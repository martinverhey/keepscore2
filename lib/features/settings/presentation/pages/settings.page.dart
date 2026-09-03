import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/config/app_version.dart';
import '../../../../core/error/failure_messages.dart';
import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/extensions/competition.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/nav_row.dart';
import '../../../../core/widgets/page_title.dart';
import '../../../../core/widgets/section_label.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/cubit/auth_bloc.dart';
import '../../../competition/domain/competition.model.dart';
import '../../../competition/presentation/cubit/competition_cubit.dart';
import '../../../competition/presentation/widgets/join_code_card.dart';
import '../../../competition/presentation/widgets/join_qr_card.dart';
import '../../domain/theme_preference.enum.dart';
import '../cubit/theme_cubit.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.competitionId});
  final String competitionId;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _showQr = false;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthBloc>().state;

    return BlocBuilder<CompetitionCubit, CompetitionState>(
      builder: (context, state) {
        setPageTitle(context, context.l10n.competitionSettings);
        return AdaptiveScaffold(
          title: context.l10n.competitionSettings,
          body: _body(context, state, session),
        );
      },
    );
  }

  Widget _body(
    BuildContext context,
    CompetitionState state,
    AuthSessionState session,
  ) {
    return switch (state) {
      CompetitionLoading() => const AdaptiveLoader(),
      CompetitionMissing() => EmptyState(
        message: context.l10n.competitionNotFound,
      ),
      CompetitionFailed(:final failure) => ErrorRetry(
        message: failure.localized(context.l10n),
        retryLabel: context.l10n.commonRetry,
        onRetry: context.read<CompetitionCubit>().load,
      ),
      CompetitionReady(:final competition) => _settings(
        context,
        competition,
        session,
      ),
    };
  }

  Widget _settings(
    BuildContext context,
    Competition competition,
    AuthSessionState session,
  ) {
    final isOwner = competition.isOwnedBySession(session);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          JoinCodeCard(code: competition.joinCode),
          _qrToggle(context, competition.joinCode),
          const SizedBox(height: AppSpacing.lg),
          SectionLabel(context.l10n.competitionSettingsSectionCompetition),
          if (session.canWrite && isOwner)
            NavRow(
              label: context.l10n.configurationTitle,
              onTap: () =>
                  context.push(Routes.configuration(widget.competitionId)),
            ),
          NavRow(
            label: context.l10n.historyTitle,
            onTap: () => context.push(Routes.history(widget.competitionId)),
          ),
          if (session.canWrite && isOwner)
            NavRow(
              label: context.l10n.playersManageTitle,
              onTap: () => context.push(Routes.players(widget.competitionId)),
            ),
          const SizedBox(height: AppSpacing.md),
          SectionLabel(context.l10n.competitionSettingsSectionSystem),
          _themeRow(context),
          NavRow(
            label: context.l10n.settingsLanguageTitle,
            onTap: () => context.push(Routes.language),
          ),
          _version(context),
          const SizedBox(height: AppSpacing.sm),
          AdaptiveButton(
            label: context.l10n.authSignOut,
            kind: AdaptiveButtonKind.plain,
            onPressed: () =>
                context.read<AuthBloc>().add(const AuthSignOutRequested()),
          ),
        ],
      ),
    );
  }

  Widget _themeRow(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) => NavRow(
        label: context.l10n.settingsDarkModeTitle,
        onTap: context.read<ThemeCubit>().toggle,
        trailing: AdaptiveSwitch(
          value: state.preference == ThemePreference.dark,
          onChanged: (_) => context.read<ThemeCubit>().toggle(),
        ),
      ),
    );
  }

  Widget _version(BuildContext context) {
    final label = AppVersion.label;
    if (label == null) return const SizedBox.shrink();

    return Text(
      context.l10n.settingsVersionLabel(label),
      textAlign: TextAlign.center,
      style: AppTypography.captionSmall,
    );
  }

  Widget _qrToggle(BuildContext context, String joinCode) {
    if (_showQr) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: JoinQrCard(code: joinCode),
      );
    }

    return Align(
      alignment: Alignment.centerRight,
      child: AdaptiveButton(
        label: context.l10n.competitionUseQrInstead,
        kind: AdaptiveButtonKind.plain,
        expand: false,
        onPressed: () => setState(() => _showQr = true),
      ),
    );
  }
}
