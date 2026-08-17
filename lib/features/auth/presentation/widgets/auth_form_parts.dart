import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure_messages.dart';
import '../../../../core/extensions/build_context_l10n.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../cubit/sign_in_cubit.dart';

class AuthHeading extends StatelessWidget {
  const AuthHeading(this.title, this.subtitle, {super.key});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(subtitle, style: const TextStyle(color: AppColors.neutral)),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class AuthFailureText extends StatelessWidget {
  const AuthFailureText({super.key});

  @override
  Widget build(BuildContext context) {
    final failure = context.select(
      (SignInCubit c) => switch (c.state) {
        SignInChooser(:final failure) => failure,
        SignInEmailStep(:final failure) => failure,
        SignInCodeStep(:final failure) => failure,
      },
    );
    if (failure == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Text(
        failure.localized(context.l10n),
        style: const TextStyle(color: AppColors.negative),
      ),
    );
  }
}

class AuthEmailStep extends StatefulWidget {
  const AuthEmailStep({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  State<AuthEmailStep> createState() => _AuthEmailStepState();
}

class _AuthEmailStepState extends State<AuthEmailStep> {
  late final TextEditingController _controller = TextEditingController(
    text: (context.read<SignInCubit>().state as SignInEmailStep).email,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SignInCubit>();
    final state = context.watch<SignInCubit>().state as SignInEmailStep;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthHeading(widget.title, widget.subtitle),
        AdaptiveTextField(
          label: context.l10n.authEmailLabel,
          controller: _controller,
          autofocus: true,
          enabled: !state.busy,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.email],
          errorText: state.email.isEmpty || state.emailIsValid
              ? null
              : context.l10n.authEmailInvalid,
          onChanged: cubit.emailChanged,
          onSubmitted: (_) => cubit.sendCode(),
        ),
        const SizedBox(height: AppSpacing.lg),
        AdaptiveButton(
          label: context.l10n.authSendCode,
          busy: state.busy,
          onPressed: state.canSendCode ? cubit.sendCode : null,
        ),
        const AuthFailureText(),
      ],
    );
  }
}

class AuthCodeStep extends StatefulWidget {
  const AuthCodeStep({super.key});

  @override
  State<AuthCodeStep> createState() => _AuthCodeStepState();
}

class _AuthCodeStepState extends State<AuthCodeStep> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SignInCubit>();
    final state = context.watch<SignInCubit>().state as SignInCodeStep;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthHeading(
          context.l10n.authCodeTitle,
          context.l10n.authCodeSubtitle(state.email),
        ),
        AdaptiveTextField(
          label: context.l10n.authCodeLabel,
          controller: _controller,
          autofocus: true,
          enabled: !state.busy,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.oneTimeCode],
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (value) {
            cubit.codeChanged(value);
            if (value.length == 6) cubit.verifyCode();
          },
          onSubmitted: (_) => cubit.verifyCode(),
        ),
        const SizedBox(height: AppSpacing.lg),
        AdaptiveButton(
          label: context.l10n.authVerify,
          busy: state.busy,
          onPressed: state.canVerify ? cubit.verifyCode : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        AdaptiveButton(
          label: context.l10n.authResendCode,
          kind: AdaptiveButtonKind.plain,
          onPressed: state.busy ? null : cubit.sendCode,
        ),
        const AuthFailureText(),
      ],
    );
  }
}
