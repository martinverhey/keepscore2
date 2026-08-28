import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/error/failure_messages.dart';
import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/page_title.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/text_entry_sheet.dart';
import '../../../auth/presentation/cubit/auth_bloc.dart';
import '../../../auth/presentation/widgets/guest_notice.dart';
import '../../domain/competition.model.dart';
import '../cubit/competition_cubit.dart';
import '../cubit/competition_list_cubit.dart';
import '../widgets/competition_action.enum.dart';
import '../widgets/competition_action_sheet.dart';
import '../widgets/competition_tile.dart';
import '../widgets/sidebar.dart';
import '../widgets/sidebar_section.enum.dart';

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

  void _selectRootSection(SidebarSection section) {
    if (section == SidebarSection.language) {
      context.push<SidebarSection>(Routes.language);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthBloc>().state;
    final hasCompetition =
        context.watch<CompetitionCubit>().state.competition != null;
    setPageTitle(context, context.l10n.competitionsTitle);

    return Sidebar(
      current: SidebarSection.competitions,
      onSelectSection: hasCompetition ? null : _selectRootSection,
      child: AdaptiveScaffold(
        title: context.l10n.competitionsTitle,
        trailing: !AppPlatform.useWideWeb(context) && !context.canPop()
            ? _signOutButton(context)
            : null,
        onRefresh: context.read<CompetitionListCubit>().refresh,
        body: BlocBuilder<CompetitionListCubit, CompetitionListState>(
          builder: (context, state) => _body(context, state, session),
        ),
      ),
    );
  }

  Widget _signOutButton(BuildContext context) => AdaptiveIconButton(
    glyph: AdaptiveGlyph.signOut,
    semanticLabel: context.l10n.authSignOut,
    onPressed: () => context.read<AuthBloc>().add(const AuthSignOutRequested()),
  );

  Widget _body(
    BuildContext context,
    CompetitionListState state,
    AuthSessionState session,
  ) {
    return switch (state) {
      CompetitionListLoading() => const AdaptiveLoader(),
      CompetitionListFailed(:final failure) => ErrorRetry(
        message: failure.localized(context.l10n),
        retryLabel: context.l10n.commonRetry,
        onRetry: context.read<CompetitionListCubit>().load,
      ),
      CompetitionListReady() => _loaded(
        context,
        state,
        canCreate: session.canWrite,
        myUserId: session.user?.id,
      ),
    };
  }

  Widget _loaded(
    BuildContext context,
    CompetitionListReady state, {
    required bool canCreate,
    required String? myUserId,
  }) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!canCreate) ...[
            GuestNotice(message: context.l10n.competitionGuestCannotCreate),
            const SizedBox(height: AppSpacing.md),
          ],

          if (state.competitions.isEmpty)
            EmptyState(message: context.l10n.competitionsEmpty)
          else
            for (final overview in state.competitions) ...[
              CompetitionTile(
                overview: overview,
                onTap: () => context.go(Routes.competition(overview.id)),
                onManage: () => _manage(context, overview, myUserId: myUserId),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],

          const SizedBox(height: AppSpacing.lg),

          if (canCreate)
            AdaptiveButton(
              label: context.l10n.competitionsCreate,
              onPressed: () => context.push(Routes.createCompetition),
            ),

          const SizedBox(height: AppSpacing.sm),
          AdaptiveButton(
            label: context.l10n.competitionsJoin,
            kind: AdaptiveButtonKind.tinted,
            onPressed: () => context.push(Routes.joinCompetition),
          ),

          if (state.actionFailure != null) _actionFailureText(context, state),
        ],
      ),
    );
  }

  Widget _actionFailureText(BuildContext context, CompetitionListReady state) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Text(
        state.actionFailure!.localized(context.l10n),
        style: const TextStyle(color: AppColors.negative),
      ),
    );
  }

  Future<void> _manage(
    BuildContext context,
    CompetitionOverview overview, {
    required String? myUserId,
  }) async {
    final cubit = context.read<CompetitionListCubit>();
    final competitionCubit = context.read<CompetitionCubit>();
    final isOwner = overview.competition.isOwnedBy(myUserId);

    final action = await showAdaptiveSheet<CompetitionAction>(
      context,
      builder: (_) => CompetitionActionSheet(
        name: overview.competition.name,
        isOwner: isOwner,
      ),
    );
    if (action == null || !context.mounted) return;

    switch (action) {
      case CompetitionAction.rename:
        final name = await showTextEntrySheet(
          context,
          title: context.l10n.competitionRenameTitle,
          fieldLabel: context.l10n.competitionNameLabel,
          submitLabel: context.l10n.competitionRename,
          initialValue: overview.competition.name,
          tooShortMessage: context.l10n.competitionNameTooShort,
        );
        if (name != null && name != overview.competition.name) {
          await cubit.rename(overview.id, name);
        }

      case CompetitionAction.leave:
        if (!context.mounted) return;
        final confirmed = await showAdaptiveConfirm(
          context,
          title: context.l10n.competitionLeaveConfirmTitle(
            overview.competition.name,
          ),
          message: context.l10n.competitionLeaveConfirmBody,
          confirmLabel: context.l10n.competitionLeave,
          cancelLabel: context.l10n.commonCancel,
          destructive: true,
        );
        if (confirmed && await cubit.leave(overview.id)) {
          competitionCubit.clearIfSelected(overview.id);
        }

      case CompetitionAction.delete:
        if (!context.mounted) return;
        final confirmed = await showAdaptiveConfirm(
          context,
          title: context.l10n.competitionDeleteConfirmTitle(
            overview.competition.name,
          ),
          message: context.l10n.competitionDeleteConfirmBody,
          confirmLabel: context.l10n.competitionDelete,
          cancelLabel: context.l10n.commonCancel,
          destructive: true,
        );
        if (confirmed && await cubit.delete(overview.id)) {
          competitionCubit.clearIfSelected(overview.id);
        }
    }
  }
}
