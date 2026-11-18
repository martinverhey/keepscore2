import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/data/recent_competition_store.dart';
import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/text_entry_sheet.dart';
import '../../domain/competition.model.dart';
import '../cubit/competition_cubit.dart';
import '../cubit/competition_list_cubit.dart';
import '../widgets/competition_actions.dart';
import '../widgets/competition_switcher_choice.dart';
import 'create_competition_sheet.dart';
import 'join_competition_sheet.dart';
import 'join_scanner_sheet.dart';

Future<void> runCompetitionSwitcherChoice(
  BuildContext context,
  CompetitionSwitcherChoice choice,
) async {
  switch (choice) {
    case CompetitionSwitchChoice(:final competitionId):
      final currentId = context.read<CompetitionCubit>().competitionId;
      if (competitionId == currentId) return;
      context.go(Routes.competition(competitionId));
    case CompetitionJoinChoice():
      await startJoinCompetition(context);
    case CompetitionCreateChoice():
      await startCreateCompetition(context);
    case CompetitionActionChoice(:final action):
      action();
  }
}

Future<void> startCreateCompetition(BuildContext context) async {
  final competitionId = await showCreateCompetitionSheet(context);
  if (competitionId == null || !context.mounted) return;
  _enterCompetition(context, competitionId);
}

Future<void> startJoinCompetition(BuildContext context) async {
  final competitionId = await _scanAndJoin(context);
  if (competitionId == null || !context.mounted) return;
  _enterCompetition(context, competitionId);
}

void _enterCompetition(BuildContext context, String competitionId) {
  context.read<CompetitionListCubit>().refresh();
  context.go(Routes.competition(competitionId));
}

Future<String?> _scanAndJoin(BuildContext context) async {
  while (true) {
    final scan = await showJoinScannerSheet(context);
    if (scan == null || !context.mounted) return null;

    final result = await showJoinCompetitionSheet(context, code: scan.code);
    if (result == null || !context.mounted) return null;
    if (result.competitionId case final competitionId?) return competitionId;
  }
}

CompetitionActions competitionActionsFor(
  BuildContext context,
  CompetitionOverview overview, {
  required String? myUserId,
}) {
  final isOwner = overview.competition.isOwnedBy(myUserId);
  final router = GoRouter.of(context);

  return CompetitionActions(
    onEdit: isOwner
        ? () => router.go(Routes.competitionEdit(overview.id))
        : null,
    onRename: isOwner ? () => _rename(context, overview) : null,
    onLeave: isOwner ? null : () => _leave(context, overview),
    onDelete: isOwner ? () => _delete(context, overview) : null,
  );
}

Future<void> _rename(BuildContext context, CompetitionOverview overview) async {
  final cubit = context.read<CompetitionListCubit>();
  final name = await showTextEntrySheet(
    context,
    title: context.l10n.competitionRenameTitle,
    fieldLabel: context.l10n.competitionNameLabel,
    submitLabel: context.l10n.competitionRename,
    initialValue: overview.competition.name,
    tooShortMessage: context.l10n.competitionNameTooShort,
  );
  if (name == null || name == overview.competition.name) return;

  await cubit.rename(overview.id, name);
}

Future<void> _leave(BuildContext context, CompetitionOverview overview) async {
  final cubit = context.read<CompetitionListCubit>();
  final competitionCubit = context.read<CompetitionCubit>();

  final confirmed = await showAdaptiveConfirm(
    context,
    title: context.l10n.competitionLeaveConfirmTitle(overview.competition.name),
    message: context.l10n.competitionLeaveConfirmBody,
    confirmLabel: context.l10n.competitionLeave,
    cancelLabel: context.l10n.commonCancel,
    destructive: true,
  );
  if (confirmed && await cubit.leave(overview.id)) {
    await _forget(competitionCubit, overview.id);
  }
}

Future<void> _delete(BuildContext context, CompetitionOverview overview) async {
  final cubit = context.read<CompetitionListCubit>();
  final competitionCubit = context.read<CompetitionCubit>();

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

Future<void> _forget(
  CompetitionCubit competitionCubit,
  String competitionId,
) async {
  competitionCubit.clearIfSelected(competitionId);
  await RecentCompetitionStore.clearIfRecent(competitionId);
}
