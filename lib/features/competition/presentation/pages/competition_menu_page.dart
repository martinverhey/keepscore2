import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/error/failure_messages.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/cubit/auth_bloc.dart';
import '../cubit/competition_detail_cubit.dart';
import '../widgets/join_code_card.dart';
import '../widgets/join_qr_card.dart';

class CompetitionMenuPage extends StatefulWidget {
  const CompetitionMenuPage({super.key, required this.competitionId});
  final String competitionId;

  @override
  State<CompetitionMenuPage> createState() => _CompetitionMenuPageState();
}

class _CompetitionMenuPageState extends State<CompetitionMenuPage> {
  bool _showQr = false;

  @override
  void initState() {
    super.initState();
    context.read<CompetitionDetailCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final session = context.watch<AuthBloc>().state;

    return BlocBuilder<CompetitionDetailCubit, CompetitionDetailState>(
      builder: (context, state) {
        final competition = state.competition;
        final isOwner = competition?.isOwnedBy(session.user?.id) ?? false;

        return AdaptiveScaffold(
          title: l10n.competitionSettings,
          body: switch (state.status) {
            CompetitionDetailStatus.loading => const AdaptiveLoader(),
            CompetitionDetailStatus.missing => EmptyState(
              message: l10n.competitionNotFound,
            ),
            CompetitionDetailStatus.failed when competition == null =>
              ErrorRetry(
                message: state.failure!.localized(l10n),
                retryLabel: l10n.commonRetry,
                onRetry: context.read<CompetitionDetailCubit>().load,
              ),
            _ => SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  JoinCodeCard(code: competition!.joinCode),
                  if (_showQr) ...[
                    const SizedBox(height: AppSpacing.sm),
                    JoinQrCard(code: competition.joinCode),
                  ] else
                    Align(
                      alignment: Alignment.centerRight,
                      child: AdaptiveButton(
                        label: l10n.competitionUseQrInstead,
                        kind: AdaptiveButtonKind.plain,
                        expand: false,
                        onPressed: () => setState(() => _showQr = true),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  _SectionHeader(title: l10n.competitionMenuSectionCompetition),
                  if (isOwner)
                    _MenuRow(
                      label: l10n.competitionSettingsTitle,
                      onTap: () => context.push(
                        Routes.competitionSettings(widget.competitionId),
                      ),
                    ),
                  _MenuRow(
                    label: l10n.playersTitle,
                    onTap: () =>
                        context.push(Routes.players(widget.competitionId)),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SectionHeader(title: l10n.competitionMenuSectionUser),
                  _MenuRow(
                    label: l10n.competitionsTitle,
                    onTap: () => context.push(Routes.home),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SectionHeader(title: l10n.competitionMenuSectionSystem),
                  _MenuRow(
                    label: l10n.settingsThemeTitle,
                    onTap: () => context.push(Routes.theme),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AdaptiveButton(
                    label: l10n.authSignOut,
                    kind: AdaptiveButtonKind.plain,
                    onPressed: () => context.read<AuthBloc>().add(
                      const AuthSignOutRequested(),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.neutral,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          borderRadius: AppRadius.card,
          color: AppColors.neutral.withValues(alpha: 0.08),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const AdaptiveIcon(
              AdaptiveGlyph.chevronRight,
              color: AppColors.neutral,
            ),
          ],
        ),
      ),
    );
  }
}
