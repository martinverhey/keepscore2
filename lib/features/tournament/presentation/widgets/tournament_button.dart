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

  bool get _isRunning => switch (state) {
    TournamentReady ready => ready.hasRunning,
    _ => false,
  };

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
      if (state case final TournamentReady ready) {
        await showTournamentBracketSheet(
          context,
          cubit: cubit,
          tournamentId: ready.latest.id,
        );
      }
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
