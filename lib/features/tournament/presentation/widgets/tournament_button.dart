import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../cubit/tournament_cubit.dart';
import '../pages/start_tournament_sheet.dart';
import '../pages/tournament_bracket_sheet.dart';

class TournamentButton extends StatelessWidget {
  const TournamentButton({
    super.key,
    required this.competitionId,
    required this.state,
    required this.isRegistered,
  });

  final String competitionId;
  final TournamentState state;
  final bool isRegistered;

  bool get _isRunning =>
      state is TournamentReady && !(state as TournamentReady).isCompleted;

  @override
  Widget build(BuildContext context) {
    return AdaptiveBarAction(
      glyph: AdaptiveGlyph.trophy,
      semanticLabel: context.l10n.tournamentTitle,
      active: _isRunning,
      onPressed: () => _open(context),
    );
  }

  Future<void> _open(BuildContext context) async {
    final cubit = context.read<TournamentCubit>();

    if (_isRunning || !isRegistered) {
      if (state is! TournamentReady) return;
      await showTournamentBracketSheet(context, cubit: cubit);
      return;
    }

    final id = await showStartTournamentSheet(
      context,
      competitionId: competitionId,
    );
    if (id == null) return;

    await cubit.refresh();
  }
}
