import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/sign_in_cubit.dart';
import '../widgets/auth_form_parts.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<SignInCubit, SignInState>(
      builder: (context, state) {
        return AdaptiveScaffold(
          title: l10n.appTitle,
          leading: state.step == SignInStep.chooser
              ? null
              : AdaptiveButton(
                  label: l10n.commonBack,
                  kind: AdaptiveButtonKind.plain,
                  expand: false,
                  onPressed: context.read<SignInCubit>().back,
                ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: switch (state.step) {
              SignInStep.chooser => const _ChooserStep(),
              SignInStep.email => AuthEmailStep(
                  title: l10n.authEmailTitle,
                  subtitle: l10n.authEmailSubtitle,
                ),
              SignInStep.code => const AuthCodeStep(),
            },
          ),
        );
      },
    );
  }
}

class _ChooserStep extends StatelessWidget {
  const _ChooserStep();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<SignInCubit>();
    final state = context.watch<SignInCubit>().state;
    final providers = cubit.providers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthHeading(l10n.authSignInTitle, l10n.authSignInSubtitle),

        if (providers.apple) ...[
          AdaptiveButton(
            label: l10n.authContinueWithApple,
            busy: state.busy,
            onPressed: cubit.signInWithApple,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (providers.google) ...[
          AdaptiveButton(
            label: l10n.authContinueWithGoogle,
            kind: AdaptiveButtonKind.tinted,
            busy: state.busy,
            onPressed: cubit.signInWithGoogle,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],

        AdaptiveButton(
          label: l10n.authContinueWithEmail,
          kind: providers.any
              ? AdaptiveButtonKind.tinted
              : AdaptiveButtonKind.filled,
          onPressed: state.busy ? null : cubit.showEmailEntry,
        ),
        const SizedBox(height: AppSpacing.lg),

        AdaptiveButton(
          label: l10n.authContinueAsGuest,
          kind: AdaptiveButtonKind.plain,
          busy: state.busy,
          onPressed: cubit.continueAsGuest,
        ),
        const AuthFailureText(),
      ],
    );
  }
}
