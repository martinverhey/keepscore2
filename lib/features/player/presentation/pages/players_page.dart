import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    final session = context.watch<AuthBloc>().state;
    final competition =
        context.watch<CompetitionDetailCubit>().state.competition;

    return AdaptiveScaffold(
      title: l10n.playersTitle,
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
