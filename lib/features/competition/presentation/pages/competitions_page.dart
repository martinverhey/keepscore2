import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/error/failure_messages.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/text_entry_sheet.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/cubit/auth_bloc.dart';
import '../../../auth/presentation/widgets/guest_notice.dart';
import '../../domain/competition.dart';
import '../cubit/competition_list_cubit.dart';
import '../widgets/competition_tile.dart';
import 'competition_action.dart';

export 'competition_action.dart';

class CompetitionsPage extends StatefulWidget {
  const CompetitionsPage({super.key});

  @override
  State<CompetitionsPage> createState() => _CompetitionsPageState();
}

class _CompetitionsPageState extends State<CompetitionsPage> {
  @override
  void initState() {
    super.initState();
    context.read<CompetitionListCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = context.watch<AuthBloc>().state;

    return AdaptiveScaffold(
      title: l10n.competitionsTitle,
      onRefresh: context.read<CompetitionListCubit>().refresh,
      body: BlocBuilder<CompetitionListCubit, CompetitionListState>(
        builder: (context, state) {
          return switch (state.status) {
            CompetitionListStatus.loading => const AdaptiveLoader(),
            CompetitionListStatus.failed when state.competitions.isEmpty =>
              ErrorRetry(
                message: state.failure!.localized(l10n),
                retryLabel: l10n.commonRetry,
                onRetry: context.read<CompetitionListCubit>().load,
              ),
            _ => _Loaded(
              state: state,
              canCreate: session.canWrite,
              myUserId: session.user?.id,
            ),
          };
        },
      ),
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({
    required this.state,
    required this.canCreate,
    required this.myUserId,
  });
  final CompetitionListState state;
  final bool canCreate;
  final String? myUserId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.competitions.isEmpty)
            EmptyState(message: l10n.competitionsEmpty)
          else
            for (final overview in state.competitions) ...[
              CompetitionTile(
                overview: overview,
                onTap: () => context.go(Routes.competition(overview.id)),
                onManage: () => _manage(context, overview),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],

          const SizedBox(height: AppSpacing.lg),

          if (canCreate)
            AdaptiveButton(
              label: l10n.competitionsCreate,
              onPressed: () => context.push(Routes.createCompetition),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: GuestNotice(message: l10n.competitionGuestCannotCreate),
            ),

          const SizedBox(height: AppSpacing.sm),
          AdaptiveButton(
            label: l10n.competitionsJoin,
            kind: AdaptiveButtonKind.tinted,
            onPressed: () => context.push(Routes.joinCompetition),
          ),

          if (state.actionFailure != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Text(
                state.actionFailure!.localized(l10n),
                style: const TextStyle(color: AppColors.negative),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _manage(
    BuildContext context,
    CompetitionOverview overview,
  ) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<CompetitionListCubit>();
    final isOwner = overview.competition.isOwnedBy(myUserId);

    final action = await showAdaptiveSheet<CompetitionAction>(
      context,
      builder: (_) => _CompetitionActionSheet(
        name: overview.competition.name,
        isOwner: isOwner,
      ),
    );
    if (action == null || !context.mounted) return;

    switch (action) {
      case CompetitionAction.rename:
        final name = await showTextEntrySheet(
          context,
          title: l10n.competitionRenameTitle,
          fieldLabel: l10n.competitionNameLabel,
          submitLabel: l10n.competitionRename,
          initialValue: overview.competition.name,
          tooShortMessage: l10n.competitionNameTooShort,
        );
        if (name != null && name != overview.competition.name) {
          await cubit.rename(overview.id, name);
        }

      case CompetitionAction.leave:
        if (!context.mounted) return;
        final confirmed = await showAdaptiveConfirm(
          context,
          title: l10n.competitionLeaveConfirmTitle(overview.competition.name),
          message: l10n.competitionLeaveConfirmBody,
          confirmLabel: l10n.competitionLeave,
          cancelLabel: l10n.commonCancel,
          destructive: true,
        );
        if (confirmed) await cubit.leave(overview.id);

      case CompetitionAction.delete:
        if (!context.mounted) return;
        final confirmed = await showAdaptiveConfirm(
          context,
          title: l10n.competitionDeleteConfirmTitle(overview.competition.name),
          message: l10n.competitionDeleteConfirmBody,
          confirmLabel: l10n.competitionDelete,
          cancelLabel: l10n.commonCancel,
          destructive: true,
        );
        if (confirmed) await cubit.delete(overview.id);
    }
  }
}

class _CompetitionActionSheet extends StatelessWidget {
  const _CompetitionActionSheet({required this.name, required this.isOwner});
  final String name;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.lg),

          if (isOwner) ...[
            AdaptiveButton(
              label: l10n.competitionRename,
              kind: AdaptiveButtonKind.tinted,
              onPressed: () =>
                  Navigator.of(context).pop(CompetitionAction.rename),
            ),
            const SizedBox(height: AppSpacing.sm),
            AdaptiveButton(
              label: l10n.competitionDelete,
              kind: AdaptiveButtonKind.destructive,
              onPressed: () =>
                  Navigator.of(context).pop(CompetitionAction.delete),
            ),
          ] else
            AdaptiveButton(
              label: l10n.competitionLeave,
              kind: AdaptiveButtonKind.destructive,
              onPressed: () =>
                  Navigator.of(context).pop(CompetitionAction.leave),
            ),

          const SizedBox(height: AppSpacing.sm),
          AdaptiveButton(
            label: l10n.commonCancel,
            kind: AdaptiveButtonKind.plain,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
