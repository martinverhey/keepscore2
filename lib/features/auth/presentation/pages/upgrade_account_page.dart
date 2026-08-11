import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../l10n/app_localizations.dart';
import '../cubit/auth_bloc.dart';
import '../cubit/sign_in_cubit.dart';
import '../widgets/auth_form_parts.dart';

class UpgradeAccountPage extends StatelessWidget {
  const UpgradeAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocListener<AuthBloc, AuthSessionState>(
      listenWhen: (previous, current) =>
          previous.isGuest && !current.isGuest && current.isAuthenticated,
      listener: (context, state) {
        if (context.canPop()) context.pop();
      },
      child: BlocBuilder<SignInCubit, SignInState>(
        builder: (context, state) {
          return AdaptiveScaffold(
            leading: AdaptiveButton(
              label: l10n.commonBack,
              kind: AdaptiveButtonKind.plain,
              expand: false,
              onPressed: state.step == SignInStep.code
                  ? context.read<SignInCubit>().back
                  : context.pop,
            ),
            body: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: switch (state.step) {
                SignInStep.code => const AuthCodeStep(),
                _ => AuthEmailStep(
                    title: l10n.authUpgradeTitle,
                    subtitle: l10n.authUpgradeBody,
                  ),
              },
            ),
          );
        },
      ),
    );
  }
}
