import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure_messages.dart';
import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/failure_text.dart';
import '../../../../core/widgets/sheet.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/cubit/auth_bloc.dart';
import '../../domain/competition.model.dart';
import '../cubit/competition_cubit.dart';
import '../cubit/competition_list_cubit.dart';
import '../widgets/competition_actions.dart';
import '../widgets/competition_switcher_choice.dart';
import '../widgets/competition_switcher_row.dart';
import 'competition_flows.dart';

Future<CompetitionSwitcherChoice?> showCompetitionSwitcherSheet(
  BuildContext context,
) {
  final competitions = context.read<CompetitionListCubit>();
  if (competitions.state is CompetitionListReady) {
    competitions.refresh();
  } else {
    competitions.ensureLoaded();
  }
  return showAdaptiveSheet<CompetitionSwitcherChoice>(
    context,
    builder: (_) => const CompetitionSwitcherSheet(),
  );
}

class CompetitionSwitcherSheet extends StatelessWidget {
  const CompetitionSwitcherSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthBloc>().state;
    final currentId = context.select<CompetitionCubit, String?>(
      (cubit) => cubit.state.competition?.id,
    );

    return BlocListener<CompetitionCubit, CompetitionState>(
      listenWhen: (previous, current) => current is CompetitionMissing,
      listener: (context, _) => Navigator.of(context).pop(),
      child: _sheet(context, session, currentId),
    );
  }

  Widget _sheet(
    BuildContext context,
    AuthSessionState session,
    String? currentId,
  ) {
    return Sheet(
      title: context.l10n.competitionsTitle,
      content: BlocBuilder<CompetitionListCubit, CompetitionListState>(
        builder: (context, state) => _content(
          context,
          state,
          currentId: currentId,
          myUserId: session.user?.id,
        ),
      ),
      primaryButton: _entryButtons(context, canCreate: session.canWrite),
    );
  }

  Widget _content(
    BuildContext context,
    CompetitionListState state, {
    required String? currentId,
    required String? myUserId,
  }) {
    return switch (state) {
      CompetitionListLoading() => const AdaptiveLoader(),
      CompetitionListFailed(:final failure) => ErrorRetry(
        message: failure.localized(context.l10n),
        retryLabel: context.l10n.commonRetry,
        onRetry: context.read<CompetitionListCubit>().load,
      ),
      CompetitionListReady() => _list(
        context,
        state,
        currentId: currentId,
        myUserId: myUserId,
      ),
    };
  }

  Widget _list(
    BuildContext context,
    CompetitionListReady state, {
    required String? currentId,
    required String? myUserId,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final overview in state.competitions)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: CompetitionSwitcherRow(
              overview: overview,
              isCurrent: overview.id == currentId,
              onTap: () =>
                  _close(context, CompetitionSwitchChoice(overview.id)),
              actions: _actions(context, overview, myUserId: myUserId),
            ),
          ),
        if (state.actionFailure case final failure?) FailureText(failure),
      ],
    );
  }

  CompetitionActions _actions(
    BuildContext context,
    CompetitionOverview overview, {
    required String? myUserId,
  }) {
    final actions = competitionActionsFor(
      context,
      overview,
      myUserId: myUserId,
    );
    return CompetitionActions(
      onEdit: switch (actions.onEdit) {
        final onEdit? => () => _close(context, CompetitionActionChoice(onEdit)),
        null => null,
      },
      onRename: actions.onRename,
      onLeave: actions.onLeave,
      onDelete: actions.onDelete,
    );
  }

  Widget _entryButtons(BuildContext context, {required bool canCreate}) {
    return Row(
      children: [
        Expanded(child: _joinButton(context)),
        if (canCreate) ...[
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: _createButton(context)),
        ],
      ],
    );
  }

  Widget _joinButton(BuildContext context) {
    return AdaptiveButton(
      label: context.l10n.competitionsJoinShort,
      kind: AdaptiveButtonKind.tinted,
      onPressed: () => _close(context, const CompetitionJoinChoice()),
    );
  }

  Widget _createButton(BuildContext context) {
    return AdaptiveButton(
      label: context.l10n.competitionsCreateShort,
      kind: AdaptiveButtonKind.tinted,
      onPressed: () => _close(context, const CompetitionCreateChoice()),
    );
  }

  void _close(BuildContext context, CompetitionSwitcherChoice choice) {
    Navigator.of(context).pop(choice);
  }
}
