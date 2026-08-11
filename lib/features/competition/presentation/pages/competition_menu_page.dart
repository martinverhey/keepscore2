import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/error/failure_messages.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../cubit/competition_detail_cubit.dart';
import '../widgets/join_code_card.dart';

class CompetitionMenuPage extends StatefulWidget {
  const CompetitionMenuPage({super.key, required this.competitionId});
  final String competitionId;

  @override
  State<CompetitionMenuPage> createState() => _CompetitionMenuPageState();
}

class _CompetitionMenuPageState extends State<CompetitionMenuPage> {
  @override
  void initState() {
    super.initState();
    context.read<CompetitionDetailCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<CompetitionDetailCubit, CompetitionDetailState>(
      builder: (context, state) {
        final competition = state.competition;

        return AdaptiveScaffold(
          title: l10n.competitionSettings,
          body: switch (state.status) {
            CompetitionDetailStatus.loading => const AdaptiveLoader(),
            CompetitionDetailStatus.missing =>
              EmptyState(message: l10n.competitionNotFound),
            CompetitionDetailStatus.failed when competition == null =>
              ErrorRetry(
                message: state.failure!.localized(l10n),
                retryLabel: l10n.commonRetry,
                onRetry: context.read<CompetitionDetailCubit>().load,
              ),
            _ => SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    JoinCodeCard(code: competition!.joinCode),
                    const SizedBox(height: AppSpacing.lg),
                    _MenuRow(
                      label: l10n.playersTitle,
                      onTap: () =>
                          context.push(Routes.players(widget.competitionId)),
                    ),
                    _MenuRow(
                      label: l10n.competitionSettingsTitle,
                      onTap: () => context.push(
                        Routes.competitionSettings(widget.competitionId),
                      ),
                    ),
                    _MenuRow(
                      label: l10n.competitionsTitle,
                      onTap: () => context.push(Routes.home),
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
