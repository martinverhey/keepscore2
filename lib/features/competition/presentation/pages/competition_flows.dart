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

Future<bool> runCompetitionSwitcherChoice(
  BuildContext context,
  CompetitionSwitcherChoice choice,
) async {
  switch (choice) {
    case CompetitionSwitchChoice(:final competitionId):
      final currentId = context.read<CompetitionCubit>().competitionId;
      if (competitionId != currentId) {
        context.go(Routes.competition(competitionId));
      }
      return true;
    case CompetitionJoinChoice():
      return _enterNew(context, joinCompetition);
    case CompetitionCreateChoice():
      return _enterNew(context, createCompetition);
    case CompetitionActionChoice(:final action):
      action();
      return true;
  }
}

Future<bool> _enterNew(
  BuildContext context,
  Future<String?> Function(BuildContext) start,
) async {
  final competitionId = await start(context);
  if (competitionId == null || !context.mounted) return false;
  context.go(Routes.competition(competitionId));
  return true;
}

Future<void> startCreateCompetition(BuildContext context) =>
    _enterNew(context, createCompetition);

Future<void> startJoinCompetition(BuildContext context) =>
    _enterNew(context, joinCompetition);

Future<String?> createCompetition(BuildContext context) async {
  final competitions = context.read<CompetitionListCubit>();
  final competitionId = await showCreateCompetitionSheet(context);
  if (competitionId != null) competitions.refresh();
  return competitionId;
}

Future<String?> joinCompetition(BuildContext context) async {
  final competitions = context.read<CompetitionListCubit>();
  final scan = await showJoinScannerSheet(context);
  if (scan == null || !context.mounted) return null;

  final competitionId = await showJoinCompetitionSheet(
    context,
    code: scan.code,
  );
  if (competitionId != null) competitions.refresh();
  return competitionId;
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
    confirmLabel: context.l10n.commonLeave,
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
    confirmLabel: context.l10n.commonDelete,
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
