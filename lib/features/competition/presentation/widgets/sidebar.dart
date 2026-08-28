import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/horizontal_divider.dart';
import '../../../../core/widgets/section_label.dart';
import '../../../auth/presentation/cubit/auth_bloc.dart';
import '../../../settings/presentation/cubit/theme_cubit.dart';
import '../../../settings/presentation/widgets/theme_glyph.dart';
import 'home_sidebar_competition.dart';
import 'sidebar_section.enum.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({
    super.key,
    required this.competition,
    required this.current,
    this.onSelectSection,
    required this.child,
  });

  final HomeSidebarCompetition? competition;
  final SidebarSection? current;
  final ValueChanged<SidebarSection>? onSelectSection;
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
    final isRegistered = context.watch<AuthBloc>().state.canWrite;

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
              onPressed: () => _select(context, SidebarSection.newMatch),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          Expanded(child: _navList(context, isRegistered: isRegistered)),
          _themeItem(context),
          _actionItem(
            context,
            label: context.l10n.settingsLanguageTitle,
            selected: current == SidebarSection.language,
            onTap: () => _select(context, SidebarSection.language),
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
    return AdaptiveTappable(
      onTap: () => _select(context, SidebarSection.competitions),
      borderRadius: AppRadius.card,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.appTitle,
              style: AppTypography.bodyMedium.copyWith(
                fontFamily: AppTypography.brandFontFamily,
                fontWeight: FontWeight.w800,
              ),
            ),
            ?_brandCompetitionName(),
          ],
        ),
      ),
    );
  }

  Widget? _brandCompetitionName() {
    final competitionName = competition?.competitionName;
    if (competitionName == null) return null;

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        competitionName,
        style: AppTypography.captionSmall.copyWith(fontWeight: FontWeight.w600),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  Widget _navList(BuildContext context, {required bool isRegistered}) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (competition != null)
            ..._competitionNavItems(context, isRegistered: isRegistered),
          SectionLabel(context.l10n.competitionSettingsSectionUser),
          _navItem(
            context,
            glyph: AdaptiveGlyph.competitions,
            label: context.l10n.competitionsTitle,
            selected: current == SidebarSection.competitions,
            onTap: () => _select(context, SidebarSection.competitions),
          ),
        ],
      ),
    );
  }

  List<Widget> _competitionNavItems(
    BuildContext context, {
    required bool isRegistered,
  }) {
    return [
      _navItem(
        context,
        glyph: AdaptiveGlyph.leaderboard,
        label: context.l10n.leaderboardTitle,
        selected: current == SidebarSection.leaderboard,
        onTap: () => _select(context, SidebarSection.leaderboard),
      ),
      _navItem(
        context,
        glyph: AdaptiveGlyph.matches,
        label: context.l10n.matchesTitle,
        selected: current == SidebarSection.matches,
        onTap: () => _select(context, SidebarSection.matches),
      ),
      const SizedBox(height: AppSpacing.lg),
      const HorizontalDivider(),
      SectionLabel(context.l10n.competitionSettingsSectionCompetition),
      if (competition!.canManageSettings)
        _navItem(
          context,
          glyph: AdaptiveGlyph.settings,
          label: context.l10n.configurationTitle,
          selected: current == SidebarSection.configuration,
          onTap: () => _select(context, SidebarSection.configuration),
        ),
      _navItem(
        context,
        glyph: AdaptiveGlyph.history,
        label: context.l10n.historyTitle,
        selected: current == SidebarSection.history,
        onTap: () => _select(context, SidebarSection.history),
      ),
      if (isRegistered)
        _navItem(
          context,
          glyph: AdaptiveGlyph.players,
          label: context.l10n.playersManageTitle,
          selected: current == SidebarSection.players,
          onTap: () => _select(context, SidebarSection.players),
        ),
      const SizedBox(height: AppSpacing.md),
    ];
  }

  Widget _themeItem(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) => _actionItem(
        context,
        label: context.l10n.settingsThemeTitle,
        onTap: context.read<ThemeCubit>().toggle,
        trailing: ThemeGlyph(preference: state.preference, size: 18),
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

  void _select(BuildContext context, SidebarSection section) {
    if (section == current) return;

    final onSelectSection = this.onSelectSection;
    if (onSelectSection != null) {
      onSelectSection(section);
      return;
    }

    if (context.canPop()) {
      context.pop(section);
    } else {
      context.go(Routes.home);
    }
  }
}
