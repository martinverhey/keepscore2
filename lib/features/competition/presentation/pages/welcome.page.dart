import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/error/failure_messages.dart';
import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/page_title.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/cubit/auth_bloc.dart';
import '../../../auth/presentation/widgets/guest_notice.dart';
import '../cubit/competition_list_cubit.dart';
import 'competition_flows.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  @override
  void initState() {
    super.initState();
    context.read<CompetitionListCubit>().ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthBloc>().state;
    setPageTitle(context, context.l10n.appTitle);

    return AdaptiveScaffold(
      onRefresh: context.read<CompetitionListCubit>().refresh,
      body: BlocConsumer<CompetitionListCubit, CompetitionListState>(
        listener: _enterFirstCompetition,
        builder: (context, state) => _body(context, state, session),
      ),
    );
  }

  void _enterFirstCompetition(
    BuildContext context,
    CompetitionListState state,
  ) {
    if (state case CompetitionListReady(
      :final competitions,
    ) when competitions.isNotEmpty) {
      context.go(Routes.competition(competitions.first.id));
    }
  }

  Widget _body(
    BuildContext context,
    CompetitionListState state,
    AuthSessionState session,
  ) {
    return switch (state) {
      CompetitionListLoading() => const AdaptiveLoader(),
      CompetitionListFailed(:final failure) => ErrorRetry(
        message: failure.localized(context.l10n),
        retryLabel: context.l10n.commonRetry,
        onRetry: context.read<CompetitionListCubit>().load,
      ),
      CompetitionListReady() => _ready(context, canCreate: session.canWrite),
    };
  }

  Widget _ready(BuildContext context, {required bool canCreate}) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [Expanded(child: _welcome(context, canCreate: canCreate))],
      ),
    );
  }

  Widget _welcome(BuildContext context, {required bool canCreate}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        _greeting(context),
        const SizedBox(height: AppSpacing.xl),
        AdaptiveButton(
          label: context.l10n.competitionsJoin,
          onPressed: () => startJoinCompetition(context),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (canCreate)
          AdaptiveButton(
            label: context.l10n.competitionsCreate,
            kind: AdaptiveButtonKind.tinted,
            onPressed: () => startCreateCompetition(context),
          )
        else
          GuestNotice(message: context.l10n.competitionGuestCannotCreate),
        const Spacer(),
        if (!AppPlatform.useWideWeb(context)) ...[
          _signOutButton(context),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ],
    );
  }

  Widget _greeting(BuildContext context) {
    return Column(
      children: [
        Text(
          context.l10n.appTitle,
          textAlign: TextAlign.center,
          style: AppTypography.headlineLarge.copyWith(
            fontFamily: AppTypography.brandFontFamily,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          context.l10n.welcomeBody,
          textAlign: TextAlign.center,
          style: AppTypography.caption,
        ),
      ],
    );
  }

  Widget _signOutButton(BuildContext context) {
    return AdaptiveButton(
      label: context.l10n.authSignOut,
      kind: AdaptiveButtonKind.plain,
      onPressed: () =>
          context.read<AuthBloc>().add(const AuthSignOutRequested()),
    );
  }
}
