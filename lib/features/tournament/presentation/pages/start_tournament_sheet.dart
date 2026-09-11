import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/dependency_injection/injector.dart';
import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/failure_text.dart';
import '../../../../core/widgets/list_header.dart';
import '../../../../core/widgets/selectable_row.dart';
import '../../../../core/widgets/sheet.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../player/domain/player.model.dart';
import '../cubit/start_tournament_cubit.dart';

Future<String?> showStartTournamentSheet(
  BuildContext context, {
  required String competitionId,
}) {
  return showAdaptiveSheet<String>(
    context,
    builder: (_) => BlocProvider(
      create: (_) => getIt<StartTournamentCubit>(param1: competitionId)..load(),
      child: const StartTournamentSheet(),
    ),
  );
}

class StartTournamentSheet extends StatelessWidget {
  const StartTournamentSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StartTournamentCubit, StartTournamentState>(
      builder: (context, state) => Sheet(
        title: context.l10n.tournamentNewTitle,
        subtitle: context.l10n.tournamentSelectHint,
        content: _content(context, state),
        primaryButton: _startButton(context, state),
      ),
    );
  }

  Widget _content(BuildContext context, StartTournamentState state) {
    return switch (state) {
      StartTournamentLoading() => const Center(child: AdaptiveLoader()),
      StartTournamentFailed(:final failure) => FailureText(failure),
      StartTournamentReady ready => _roster(context, ready),
    };
  }

  Widget _roster(BuildContext context, StartTournamentReady state) {
    if (state.players.isEmpty) {
      return EmptyState(message: context.l10n.playersEmpty);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ListHeader(
          title: context.l10n.tournamentSelectedCount(
            state.selected.length,
            StartTournamentReady.maxPlayers,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final player in state.players) ...[
          _row(context, state, player),
          const SizedBox(height: AppSpacing.xs),
        ],
        if (state.actionFailure case final failure?) FailureText(failure),
      ],
    );
  }

  Widget _row(
    BuildContext context,
    StartTournamentReady state,
    Player player,
  ) {
    final selectable = state.canSelect(player.id);

    return SelectableRow(
      label: player.displayName,
      selected: state.isSelected(player.id),
      labelColor: selectable ? null : AppColors.neutral,
      onTap: () => context.read<StartTournamentCubit>().toggle(player.id),
    );
  }

  Widget? _startButton(BuildContext context, StartTournamentState state) {
    if (state is! StartTournamentReady) return null;

    return AdaptiveButton(
      label: context.l10n.tournamentStart,
      busy: state.busy,
      onPressed: state.canStart ? () => _start(context) : null,
    );
  }

  Future<void> _start(BuildContext context) async {
    final navigator = Navigator.of(context);
    final id = await context.read<StartTournamentCubit>().start();
    if (id == null || !navigator.mounted) return;

    navigator.pop(id);
  }
}
