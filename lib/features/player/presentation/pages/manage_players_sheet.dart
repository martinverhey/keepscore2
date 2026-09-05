import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/dependency_injection/injector.dart';
import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/extensions/competition.extension.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/sheet.dart';
import '../../../auth/presentation/cubit/auth_bloc.dart';
import '../../../competition/presentation/cubit/competition_cubit.dart';
import '../cubit/players_cubit.dart';
import '../widgets/players.dart';

Future<void> showManagePlayersSheet(
  BuildContext context, {
  required String competitionId,
}) {
  return showAdaptiveSheet<void>(
    context,
    builder: (_) => BlocProvider(
      create: (_) => getIt<PlayersCubit>(param1: competitionId)..load(),
      child: const ManagePlayersSheet(),
    ),
  );
}

class ManagePlayersSheet extends StatelessWidget {
  const ManagePlayersSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthBloc>().state;
    final competition = context.watch<CompetitionCubit>().state.competition;
    final isOwner = session.canWrite && competition.isOwnedBySession(session);

    return Sheet(
      title: context.l10n.playersManageTitle,
      content: Players(
        ownerUserId: competition?.ownerId,
        myUserId: session.user?.id,
        isRegistered: session.canWrite,
      ),
      primaryButton: isOwner ? _addPlayerButton(context) : null,
      secondaryButton: AdaptiveButton(
        label: context.l10n.commonDone,
        kind: AdaptiveButtonKind.plain,
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  AdaptiveButton _addPlayerButton(BuildContext context) {
    final state = context.watch<PlayersCubit>().state;
    return AdaptiveButton(
      label: context.l10n.playersAddPlayer,
      busy: state is PlayersReady && state.busy,
      onPressed: () => addPlaceholderPlayer(context),
    );
  }
}
