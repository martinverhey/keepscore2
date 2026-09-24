import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/config/app_version.dart';
import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/nav_row.dart';
import '../../../../core/widgets/page_title.dart';
import '../../../../core/widgets/section_label.dart';
import '../../../auth/presentation/cubit/auth_bloc.dart';
import '../../domain/theme_preference.enum.dart';
import '../cubit/theme_cubit.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    setPageTitle(context, context.l10n.profilePageTitle);
    return AdaptiveScaffold(
      title: context.l10n.profilePageTitle,
      body: _profile(context),
    );
  }

  Widget _profile(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionLabel(context.l10n.competitionSettingsSectionSystem),
          _themeRow(context),
          NavRow(
            label: context.l10n.settingsLanguageTitle,
            onTap: () => context.push(Routes.language),
          ),
          const SizedBox(height: AppSpacing.xxl),
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
}
