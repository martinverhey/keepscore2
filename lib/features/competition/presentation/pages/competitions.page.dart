import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/data/recent_competition_store.dart';
import '../../../../core/error/failure_messages.dart';
import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/list_header.dart';
import '../../../../core/widgets/page_title.dart';
import '../../../../core/widgets/speech_bubble.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/text_entry_sheet.dart';
import '../../../auth/presentation/cubit/auth_bloc.dart';
import '../../../auth/presentation/widgets/guest_notice.dart';
import '../../domain/competition.model.dart';
import '../cubit/competition_cubit.dart';
import '../cubit/competition_list_cubit.dart';
import '../widgets/active_competition_card.dart';
import '../widgets/competition_action.enum.dart';
import '../widgets/competition_action_sheet.dart';
import '../widgets/create_competition_sheet.dart';
import '../widgets/join_competition_sheet.dart';
import '../widgets/join_scanner_sheet.dart';
import '../widgets/competition_card.dart';

const double _joinTailInset = 10;
const double _createTailInset = 90;

class CompetitionsPage extends StatefulWidget {
  const CompetitionsPage({super.key});

  @override
  State<CompetitionsPage> createState() => _CompetitionsPageState();
}

class _CompetitionsPageState extends State<CompetitionsPage> {
  @override
  void initState() {
    super.initState();
    context.read<CompetitionListCubit>().ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthBloc>().state;
    setPageTitle(context, context.l10n.competitionsTitle);

    return AdaptiveScaffold(
      title: context.l10n.competitionsTitle,
      trailing: _actions(context, canCreate: session.canWrite),
      onRefresh: context.read<CompetitionListCubit>().refresh,
      body: BlocBuilder<CompetitionListCubit, CompetitionListState>(
        builder: (context, state) => _body(context, state, session),
      ),
    );
  }

  Widget _actions(BuildContext context, {required bool canCreate}) {
    return AdaptiveBarActionGroup(
      actions: [if (canCreate) _createButton(context), _joinButton(context)],
    );
  }

  Widget _createButton(BuildContext context) => AdaptiveBarAction(
    glyph: AdaptiveGlyph.add,
    semanticLabel: context.l10n.competitionsAdd,
    onPressed: () => _create(context),
  );

  Widget _joinButton(BuildContext context) => AdaptiveBarAction(
    label: context.l10n.competitionsJoinShort,
    semanticLabel: context.l10n.competitionsJoin,
    onPressed: () => _join(context),
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
    final active = _active(context, state);
    final others = state.competitions
        .where((overview) => overview.id != active?.id)
        .toList();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!canCreate) ...[
            GuestNotice(message: context.l10n.competitionGuestCannotCreate),
            const SizedBox(height: AppSpacing.md),
          ],

          if (active case final active?) ...[
            _activeSection(
              context,
              active,
              myUserId: myUserId,
              hasOthers: others.isNotEmpty,
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          if (state.competitions.isEmpty)
            Expanded(child: _emptySection(context, canCreate: canCreate))
          else
            for (final overview in others) ...[
              CompetitionCard(
                overview: overview,
                onTap: () => context.go(Routes.competition(overview.id)),
                onManage: () => _manage(context, overview, myUserId: myUserId),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],

          if (state.actionFailure != null) _actionFailureText(context, state),
        ],
      ),
    );
  }

  CompetitionOverview? _active(
    BuildContext context,
    CompetitionListReady state,
  ) {
    final activeId = context.watch<CompetitionCubit>().state.competition?.id;
    if (activeId == null) return null;
    for (final overview in state.competitions) {
      if (overview.id == activeId) return overview;
    }
    return null;
  }

  Widget _activeSection(
    BuildContext context,
    CompetitionOverview active, {
    required String? myUserId,
    required bool hasOthers,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActiveCompetitionCard(
          overview: active,
          onOpen: () => context.go(Routes.competition(active.id)),
          onManage: () => _manage(context, active, myUserId: myUserId),
        ),
        if (hasOthers) ...[
          const SizedBox(height: AppSpacing.lg),
          ListHeader(title: context.l10n.competitionsOther),
        ],
      ],
    );
  }

  Widget _emptySection(BuildContext context, {required bool canCreate}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _joinBubble(context),
        if (canCreate) ...[
          const SizedBox(height: AppSpacing.sm),
          _createBubble(context),
        ],
        const Spacer(),
        EmptyState(message: context.l10n.competitionsPlaceholder),
        const Spacer(),
        if (!AppPlatform.useWideWeb(context)) ...[
          _signOutButton(context),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ],
    );
  }

  Widget _joinBubble(BuildContext context) => _tipBubble(
    context,
    title: context.l10n.competitionsJoinShort,
    body: context.l10n.competitionsJoinTip,
    tailInset: _joinTailInset,
  );

  Widget _createBubble(BuildContext context) => _tipBubble(
    context,
    title: context.l10n.competitionsCreateShort,
    body: context.l10n.competitionsCreateTip,
    tailInset: _createTailInset,
  );

  Widget _tipBubble(
    BuildContext context, {
    required String title,
    required String body,
    required double tailInset,
  }) {
    return SpeechBubble(
      color: AppColors.neutralSurface,
      tailInset: tailInset,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.eyebrow.copyWith(
              color: AdaptiveColors.accent(context),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(body, style: AppTypography.caption),
        ],
      ),
    );
  }

  Widget _signOutButton(BuildContext context) {
    return AdaptiveButton(
      label: context.l10n.authSignOut,
      kind: AdaptiveButtonKind.plain,
      onPressed: () =>
          context.read<AuthBloc>().add(const AuthSignOutRequested()),
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

  Future<void> _create(BuildContext context) async {
    final competitionId = await showCreateCompetitionSheet(context);
    if (competitionId == null || !context.mounted) return;

    context.read<CompetitionListCubit>().refresh();
    context.go(Routes.competition(competitionId));
  }

  Future<void> _join(BuildContext context) async {
    final scan = await showJoinScannerSheet(context);
    if (scan == null || !context.mounted) return;

    final competitionId = await showJoinCompetitionSheet(
      context,
      code: scan.code,
    );
    if (competitionId == null || !context.mounted) return;

    context.read<CompetitionListCubit>().refresh();
    context.go(Routes.competition(competitionId));
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
          await _forget(competitionCubit, overview.id);
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
          await _forget(competitionCubit, overview.id);
        }
    }
  }

  Future<void> _forget(
    CompetitionCubit competitionCubit,
    String competitionId,
  ) async {
    competitionCubit.clearIfSelected(competitionId);
    await RecentCompetitionStore.clearIfRecent(competitionId);
  }
}
