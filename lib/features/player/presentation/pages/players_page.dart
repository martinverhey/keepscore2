import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/build_context_l10n.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../auth/presentation/cubit/auth_bloc.dart';
import '../../../competition/presentation/cubit/competition_detail_cubit.dart';
import '../cubit/players_cubit.dart';
import '../widgets/players.dart';

class PlayersPage extends StatefulWidget {
  const PlayersPage({super.key});

  @override
  State<PlayersPage> createState() => _PlayersPageState();
}

class _PlayersPageState extends State<PlayersPage> {
  @override
  void initState() {
    super.initState();
    context.read<CompetitionDetailCubit>().load();
    context.read<PlayersCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthBloc>().state;
    final competition = context
        .watch<CompetitionDetailCubit>()
        .state
        .competition;
    final isOwner =
        session.canWrite &&
        session.user?.id != null &&
        session.user?.id == competition?.ownerId;

    return AdaptiveScaffold(
      title: context.l10n.playersTitle,
      trailing: isOwner
          ? AdaptiveIconButton(
              glyph: AdaptiveGlyph.add,
              semanticLabel: context.l10n.playersAddDummy,
              onPressed: () => addPlaceholderPlayer(context),
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Players(
          ownerUserId: competition?.ownerId,
          myUserId: session.user?.id,
          isRegistered: session.canWrite,
        ),
      ),
    );
  }
}
