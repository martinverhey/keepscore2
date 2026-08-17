import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/build_context_l10n.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../cubit/sign_in_cubit.dart';
import '../widgets/auth_form_parts.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignInCubit, SignInState>(
      builder: (context, state) {
        return AdaptiveScaffold(
          leading: state is SignInChooser
              ? null
              : AdaptiveButton(
                  label: context.l10n.commonBack,
                  kind: AdaptiveButtonKind.plain,
                  expand: false,
                  onPressed: context.read<SignInCubit>().back,
                ),
          body: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: switch (state) {
              SignInChooser() => _chooserStep(context, state),
              SignInEmailStep() => AuthEmailStep(
                title: context.l10n.authEmailTitle,
                subtitle: context.l10n.authEmailSubtitle,
              ),
              SignInCodeStep() => const AuthCodeStep(),
            },
          ),
        );
      },
    );
  }

  Widget _chooserStep(BuildContext context, SignInChooser state) {
    final cubit = context.read<SignInCubit>();
    final providers = cubit.providers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xxl),
        AuthHeading(
          context.l10n.authSignInTitle,
          context.l10n.authSignInSubtitle,
        ),

        if (providers.apple) ...[
          AdaptiveButton(
            label: context.l10n.authContinueWithApple,
            busy: state.busy,
            onPressed: cubit.signInWithApple,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (providers.google) ...[
          AdaptiveButton(
            label: context.l10n.authContinueWithGoogle,
            kind: AdaptiveButtonKind.tinted,
            busy: state.busy,
            onPressed: cubit.signInWithGoogle,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],

        AdaptiveButton(
          label: context.l10n.authContinueWithEmail,
          kind: providers.any
              ? AdaptiveButtonKind.tinted
              : AdaptiveButtonKind.filled,
          onPressed: state.busy ? null : cubit.showEmailEntry,
        ),
        const SizedBox(height: AppSpacing.lg),

        AdaptiveButton(
          label: context.l10n.authContinueAsGuest,
          kind: AdaptiveButtonKind.plain,
          busy: state.busy,
          onPressed: cubit.continueAsGuest,
        ),
        const AuthFailureText(),
      ],
    );
  }
}
