import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/error/failure_messages.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/cubit/auth_bloc.dart';
import '../../../auth/presentation/widgets/guest_notice.dart';
import '../cubit/competition_list_cubit.dart';
import '../widgets/competition_tile.dart';

class CompetitionsPage extends StatefulWidget {
  const CompetitionsPage({super.key});

  @override
  State<CompetitionsPage> createState() => _CompetitionsPageState();
}

class _CompetitionsPageState extends State<CompetitionsPage> {
  @override
  void initState() {
    super.initState();
    context.read<CompetitionListCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = context.watch<AuthBloc>().state;

    return AdaptiveScaffold(
      title: l10n.competitionsTitle,
      trailing: AdaptiveButton(
        label: l10n.authSignOut,
        kind: AdaptiveButtonKind.plain,
        expand: false,
        onPressed: () =>
            context.read<AuthBloc>().add(const AuthSignOutRequested()),
      ),
      body: BlocBuilder<CompetitionListCubit, CompetitionListState>(
        builder: (context, state) {
          final body = switch (state.status) {
            CompetitionListStatus.loading => const AdaptiveLoader(),
            CompetitionListStatus.failed when state.competitions.isEmpty =>
              ErrorRetry(
                message: state.failure!.localized(l10n),
                retryLabel: l10n.commonRetry,
                onRetry: context.read<CompetitionListCubit>().load,
              ),
            _ => _Loaded(state: state, canCreate: session.canWrite),
          };

          return AdaptiveRefresh(
            onRefresh: context.read<CompetitionListCubit>().refresh,
            child: body,
          );
        },
      ),
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({required this.state, required this.canCreate});
  final CompetitionListState state;
  final bool canCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.competitions.isEmpty)
            EmptyState(message: l10n.competitionsEmpty)
          else
            for (final overview in state.competitions) ...[
              CompetitionTile(
                overview: overview,
                onTap: () => context.push('/c/${overview.id}'),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],

          const SizedBox(height: AppSpacing.lg),

          if (canCreate)
            AdaptiveButton(
              label: l10n.competitionsCreate,
              onPressed: () => context.push(Routes.createCompetition),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: GuestNotice(message: l10n.competitionGuestCannotCreate),
            ),

          const SizedBox(height: AppSpacing.sm),
          AdaptiveButton(
            label: l10n.competitionsJoin,
            kind: AdaptiveButtonKind.tinted,
            onPressed: () => context.push(Routes.joinCompetition),
          ),
        ],
      ),
    );
  }
}
