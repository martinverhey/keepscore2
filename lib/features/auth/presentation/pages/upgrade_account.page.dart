import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../cubit/auth_bloc.dart';
import '../cubit/sign_in_cubit.dart';
import '../widgets/auth_form_parts.dart';

class UpgradeAccountPage extends StatelessWidget {
  const UpgradeAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
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
              label: context.l10n.commonBack,
              kind: AdaptiveButtonKind.plain,
              expand: false,
              onPressed: state is SignInCodeStep
                  ? context.read<SignInCubit>().back
                  : context.pop,
            ),
            body: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: switch (state) {
                SignInCodeStep() => const AuthCodeStep(),
                _ => AuthEmailStep(
                  title: context.l10n.authUpgradeTitle,
                  subtitle: context.l10n.authUpgradeBody,
                ),
              },
            ),
          );
        },
      ),
    );
  }
}
