import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../cubit/auth_cubit.dart';

Future<void> signOut(BuildContext context) async {
  final auth = context.read<AuthCubit>();
  if (auth.state.isGuest && !await _confirmGuestSignOut(context)) return;
  await auth.signOut();
}

Future<bool> _confirmGuestSignOut(BuildContext context) {
  return showAdaptiveConfirm(
    context,
    title: context.l10n.authSignOutGuestConfirmTitle,
    message: context.l10n.authSignOutGuestConfirmBody,
    confirmLabel: context.l10n.authSignOut,
    cancelLabel: context.l10n.commonCancel,
    destructive: true,
  );
}
