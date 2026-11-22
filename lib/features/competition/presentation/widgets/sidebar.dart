import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../auth/presentation/cubit/auth_bloc.dart';
import '../../../match/presentation/pages/new_match_sheet.dart';
import '../../../settings/domain/theme_preference.enum.dart';
import '../../../settings/presentation/cubit/theme_cubit.dart';
import '../cubit/competition_cubit.dart';
import 'sidebar_section.enum.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({
    super.key,
    required this.current,
    required this.onSelectSection,
    required this.child,
  });

  final SidebarSection? current;
  final ValueChanged<SidebarSection> onSelectSection;
  final Widget child;

  static const _width = 232.0;

  @override
  Widget build(BuildContext context) {
    if (!AppPlatform.useWideWeb(context)) return child;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdaptiveMaterialScope(child: _content(context)),
        Expanded(child: SuppressedBackButtonScope(child: child)),
      ],
    );
  }

  Widget _content(BuildContext context) {
    final session = context.watch<AuthBloc>().state;
    final competition = context.watch<CompetitionCubit>().state.competition;
    final isRegistered = session.canWrite;

    return Container(
      width: _width,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AdaptiveColors.surfaceTint(context),
        border: Border(
          right: BorderSide(color: AdaptiveColors.divider(context)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _brand(context),
          const SizedBox(height: AppSpacing.lg),
          if (competition != null && isRegistered) ...[
            AdaptiveButton(
              label: context.l10n.matchNew,
              icon: const AdaptiveIcon(AdaptiveGlyph.newMatch, size: 18),
              onPressed: () =>
                  showNewMatchSheet(context, competitionId: competition.id),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          Expanded(
            child: _navList(context, hasCompetition: competition != null),
          ),
          _themeItem(context),
          _actionItem(
            context,
            label: context.l10n.settingsLanguageTitle,
            selected: current == SidebarSection.language,
            onTap: () => _select(SidebarSection.language),
          ),
          _actionItem(
            context,
            label: context.l10n.authSignOut,
            onTap: () =>
                context.read<AuthBloc>().add(const AuthSignOutRequested()),
          ),
        ],
      ),
    );
  }

  Widget _brand(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Text(
        context.l10n.appTitle,
        style: AppTypography.bodyMedium.copyWith(
          fontFamily: AppTypography.brandFontFamily,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _navList(BuildContext context, {required bool hasCompetition}) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [if (hasCompetition) ..._competitionNavItems(context)],
      ),
    );
  }

  List<Widget> _competitionNavItems(BuildContext context) {
    return [
      _navItem(
        context,
        glyph: AdaptiveGlyph.leaderboard,
        label: context.l10n.leaderboardTitle,
        selected: current == SidebarSection.leaderboard,
        onTap: () => _select(SidebarSection.leaderboard),
      ),
      _navItem(
        context,
        glyph: AdaptiveGlyph.matches,
        label: context.l10n.matchesTitle,
        selected: current == SidebarSection.matches,
        onTap: () => _select(SidebarSection.matches),
      ),
      const SizedBox(height: AppSpacing.md),
    ];
  }

  Widget _themeItem(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) => _actionItem(
        context,
        label: context.l10n.settingsDarkModeTitle,
        onTap: context.read<ThemeCubit>().toggle,
        trailing: AdaptiveSwitch(
          value: state.preference == ThemePreference.dark,
          onChanged: (_) => context.read<ThemeCubit>().toggle(),
        ),
      ),
    );
  }

  Widget _navItem(
    BuildContext context, {
    required AdaptiveGlyph glyph,
    required String label,
    required VoidCallback onTap,
    bool selected = false,
  }) {
    final accent = AdaptiveColors.accent(context);

    return _item(
      context,
      onTap: onTap,
      selected: selected,
      child: Row(
        children: [
          AdaptiveIcon(
            glyph,
            size: 18,
            color: selected ? accent : AppColors.neutral,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? accent : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionItem(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
    Widget? trailing,
    bool selected = false,
  }) {
    return _item(
      context,
      onTap: onTap,
      selected: selected,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w400,
                color: selected
                    ? AdaptiveColors.accent(context)
                    : AppColors.neutral,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  Widget _item(
    BuildContext context, {
    required VoidCallback onTap,
    required bool selected,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: AdaptiveTappable(
        onTap: onTap,
        borderRadius: AppRadius.card,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.card,
            color: selected
                ? AdaptiveColors.accent(
                    context,
                  ).withValues(alpha: AppOpacity.selectedFill)
                : null,
          ),
          child: child,
        ),
      ),
    );
  }

  void _select(SidebarSection section) {
    if (section == current) return;
    onSelectSection(section);
  }
}
