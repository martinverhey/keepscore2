import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/page_title.dart';
import '../../../auth/presentation/cubit/auth_bloc.dart';
import '../../../competition/presentation/widgets/home_sidebar_competition.dart';
import '../../../competition/presentation/widgets/open_home.dart';
import '../../../competition/presentation/widgets/select_competition_section.dart';
import '../../../competition/presentation/widgets/sidebar.dart';
import '../../domain/theme_preference.enum.dart';
import '../cubit/theme_cubit.dart';

class ThemePage extends StatelessWidget {
  const ThemePage({super.key, this.sidebarCompetition});

  final HomeSidebarCompetition? sidebarCompetition;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ThemeCubit>();
    final session = context.watch<AuthBloc>().state;
    final sidebarCompetition = this.sidebarCompetition;

    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        setPageTitle(context, context.l10n.settingsThemeTitle);

        return Sidebar(
          competitionName: sidebarCompetition?.competitionName,
          current: null,
          hasCompetition: sidebarCompetition != null,
          canManageSettings: sidebarCompetition?.canManageSettings ?? false,
          isRegistered: session.canWrite,
          onSelectSection: sidebarCompetition == null
              ? (_) {}
              : (section) => selectCompetitionSection(
                  context,
                  competitionId: sidebarCompetition.competitionId,
                  target: section,
                ),
          onNewMatch: sidebarCompetition == null
              ? () {}
              : () => context.push<Object?>(
                  Routes.newMatch(sidebarCompetition.competitionId),
                ),
          onOpenHome: sidebarCompetition == null
              ? () => context.pushReplacement(Routes.home)
              : () => openHome(
                  context,
                  replace: true,
                  competitionId: sidebarCompetition.competitionId,
                  competitionName: sidebarCompetition.competitionName,
                  canManageSettings: sidebarCompetition.canManageSettings,
                ),
          onOpenTheme: () {},
          onSignOut: () =>
              context.read<AuthBloc>().add(const AuthSignOutRequested()),
          child: AdaptiveScaffold(
            title: context.l10n.settingsThemeTitle,
            body: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AdaptiveSegmented<ThemePreference>(
                value: state.preference,
                onChanged: cubit.select,
                segments: {
                  ThemePreference.system: context.l10n.themeOptionSystem,
                  ThemePreference.light: context.l10n.themeOptionLight,
                  ThemePreference.dark: context.l10n.themeOptionDark,
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
