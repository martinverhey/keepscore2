import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/extensions/competition.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/page_title.dart';
import '../../../auth/presentation/cubit/auth_bloc.dart';
import '../../../competition/presentation/cubit/competition_cubit.dart';
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
    context.read<PlayersCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthBloc>().state;
    final competition = context.watch<CompetitionCubit>().state.competition;
    final isOwner = session.canWrite && competition.isOwnedBySession(session);
    setPageTitle(context, context.l10n.playersTitle);

    return AdaptiveScaffold(
      title: context.l10n.playersTitle,
      floatingAction: isOwner ? _addPlayerButton(context) : null,
      body: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.md,
          bottom: isOwner ? _floatingActionInset : AppSpacing.md,
        ),
        child: Players(
          ownerUserId: competition?.ownerId,
          myUserId: session.user?.id,
          isRegistered: session.canWrite,
        ),
      ),
    );
  }

  Widget _addPlayerButton(BuildContext context) {
    return BlocBuilder<PlayersCubit, PlayersState>(
      builder: (context, state) => AdaptiveFloatingAction(
        glyph: AdaptiveGlyph.add,
        semanticLabel: context.l10n.playersAddDummy,
        busy: state is PlayersReady && state.busy,
        onPressed: () => addPlaceholderPlayer(context),
      ),
    );
  }

  static const double _floatingActionInset =
      AdaptiveFloatingAction.diameter + AppSpacing.lg;
}
