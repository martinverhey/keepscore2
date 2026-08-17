import 'package:flutter/widgets.dart';

import '../../../../core/extensions/build_context_l10n.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/horizontal_divider.dart';
import '../../../../core/widgets/section_label.dart';
import 'competition_section.enum.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({
    super.key,
    required this.competitionName,
    required this.current,
    this.hasCompetition = true,
    required this.canManageSettings,
    required this.isRegistered,
    required this.onSelectSection,
    required this.onNewMatch,
    required this.onOpenHome,
    required this.onOpenTheme,
    required this.onSignOut,
    required this.child,
  });

  final String? competitionName;
  final CompetitionSection? current;
  final bool hasCompetition;
  final bool canManageSettings;
  final bool isRegistered;
  final ValueChanged<CompetitionSection> onSelectSection;
  final VoidCallback onNewMatch;
  final VoidCallback onOpenHome;
  final VoidCallback onOpenTheme;
  final VoidCallback onSignOut;
  final Widget child;

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
    return Container(
      width: 232,
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
          if (hasCompetition && isRegistered) ...[
            AdaptiveButton(
              label: context.l10n.matchNew,
              icon: const AdaptiveIcon(AdaptiveGlyph.newMatch, size: 18),
              onPressed: onNewMatch,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasCompetition) ...[
                    _navItem(
                      context,
                      glyph: AdaptiveGlyph.leaderboard,
                      label: context.l10n.leaderboardTitle,
                      selected: current == CompetitionSection.leaderboard,
                      onTap: () =>
                          onSelectSection(CompetitionSection.leaderboard),
                    ),
                    _navItem(
                      context,
                      glyph: AdaptiveGlyph.matches,
                      label: context.l10n.matchesTitle,
                      selected: current == CompetitionSection.matches,
                      onTap: () =>
                          onSelectSection(CompetitionSection.matches),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const HorizontalDivider(),
                    SectionLabel(
                      context.l10n.competitionMenuSectionCompetition,
                    ),
                    if (canManageSettings)
                      _navItem(
                        context,
                        glyph: AdaptiveGlyph.settings,
                        label: context.l10n.competitionSettingsTitle,
                        selected: current == CompetitionSection.settings,
                        onTap: () =>
                            onSelectSection(CompetitionSection.settings),
                      ),
                    _navItem(
                      context,
                      glyph: AdaptiveGlyph.history,
                      label: context.l10n.historyTitle,
                      selected: current == CompetitionSection.history,
                      onTap: () =>
                          onSelectSection(CompetitionSection.history),
                    ),
                    if (isRegistered)
                      _navItem(
                        context,
                        glyph: AdaptiveGlyph.players,
                        label: context.l10n.playersManageTitle,
                        selected: current == CompetitionSection.players,
                        onTap: () =>
                            onSelectSection(CompetitionSection.players),
                      ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  SectionLabel(context.l10n.competitionMenuSectionUser),
                  _navItem(
                    context,
                    glyph: AdaptiveGlyph.competitions,
                    label: context.l10n.competitionsTitle,
                    selected: current == CompetitionSection.competitions,
                    onTap: onOpenHome,
                  ),
                ],
              ),
            ),
          ),
          _actionItem(
            context,
            label: context.l10n.settingsThemeTitle,
            onTap: onOpenTheme,
          ),
          _actionItem(
            context,
            label: context.l10n.authSignOut,
            onTap: onSignOut,
          ),
        ],
      ),
    );
  }

  Widget _brand(BuildContext context) {
    return AdaptiveTappable(
      onTap: onOpenHome,
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
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            if (competitionName != null) ...[
              const SizedBox(height: 2),
              Text(
                competitionName!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.neutral,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ],
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
            color: selected ? accent.withValues(alpha: 0.14) : null,
          ),
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
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? accent : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionItem(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
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
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: AppColors.neutral),
          ),
        ),
      ),
    );
  }
}
