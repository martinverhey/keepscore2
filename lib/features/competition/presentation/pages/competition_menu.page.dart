import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/error/failure_messages.dart';
import '../../../../core/extensions/build_context_l10n.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/nav_row.dart';
import '../../../../core/widgets/page_title.dart';
import '../../../../core/widgets/section_label.dart';
import '../../../../core/widgets/state_views.dart';
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
    final session = context.watch<AuthBloc>().state;

    return BlocBuilder<CompetitionDetailCubit, CompetitionDetailState>(
      builder: (context, state) {
        final competition = state.competition;
        final isOwner = competition?.isOwnedBy(session.user?.id) ?? false;
        setPageTitle(context, context.l10n.competitionSettings);

        return AdaptiveScaffold(
          title: context.l10n.competitionSettings,
          body: switch (state.status) {
            CompetitionDetailStatus.loading => const AdaptiveLoader(),
            CompetitionDetailStatus.missing => EmptyState(
              message: context.l10n.competitionNotFound,
            ),
            CompetitionDetailStatus.failed when competition == null =>
              ErrorRetry(
                message: state.failure!.localized(context.l10n),
                retryLabel: context.l10n.commonRetry,
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
                        label: context.l10n.competitionUseQrInstead,
                        kind: AdaptiveButtonKind.plain,
                        expand: false,
                        onPressed: () => setState(() => _showQr = true),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  SectionLabel(context.l10n.competitionMenuSectionCompetition),
                  if (session.canWrite && isOwner)
                    NavRow(
                      label: context.l10n.competitionSettingsTitle,
                      onTap: () => context.push(
                        Routes.competitionSettings(widget.competitionId),
                      ),
                    ),
                  NavRow(
                    label: context.l10n.historyTitle,
                    onTap: () => context.push(
                      Routes.history(widget.competitionId),
                    ),
                  ),
                  if (session.canWrite)
                    NavRow(
                      label: context.l10n.playersManageTitle,
                      onTap: () =>
                          context.push(Routes.players(widget.competitionId)),
                    ),
                  const SizedBox(height: AppSpacing.md),
                  SectionLabel(context.l10n.competitionMenuSectionUser),
                  NavRow(
                    label: context.l10n.competitionsTitle,
                    onTap: () => context.push(Routes.home),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SectionLabel(context.l10n.competitionMenuSectionSystem),
                  NavRow(
                    label: context.l10n.settingsThemeTitle,
                    onTap: () => context.push(Routes.theme),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AdaptiveButton(
                    label: context.l10n.authSignOut,
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
