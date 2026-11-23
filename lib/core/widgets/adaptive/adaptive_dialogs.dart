import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../theme/app_tokens.dart';
import '../scroll_dismissible_sheet.dart';
import 'adaptive_colors.dart';
import 'adaptive_glass.dart';
import 'app_platform.dart';

Future<bool> showAdaptiveConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
  bool destructive = false,
}) {
  final future = AppPlatform.useCupertino
      ? showCupertinoDialog<bool>(
          context: context,
          builder: (dialogContext) => CupertinoAlertDialog(
            title: Text(title),
            content: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(message),
            ),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: destructive,
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(cancelLabel),
              ),
              CupertinoDialogAction(
                isDefaultAction: !destructive,
                isDestructiveAction: destructive,
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(confirmLabel),
              ),
            ],
          ),
        )
      : showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              _materialConfirmActions(
                dialogContext,
                confirmLabel: confirmLabel,
                cancelLabel: cancelLabel,
                destructive: destructive,
              ),
            ],
          ),
        );
  return future.then((value) => value ?? false);
}

Widget _materialConfirmActions(
  BuildContext context, {
  required String confirmLabel,
  required String cancelLabel,
  required bool destructive,
}) {
  return Row(
    children: [
      Expanded(
        child: TextButton(
          style: _materialConfirmButtonStyle(),
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
      ),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: TextButton(
          style: _materialConfirmButtonStyle(
            foregroundColor: destructive
                ? Theme.of(context).colorScheme.error
                : null,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ),
    ],
  );
}

ButtonStyle _materialConfirmButtonStyle({Color? foregroundColor}) {
  return TextButton.styleFrom(
    foregroundColor: foregroundColor,
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
  );
}

Future<T?> showAdaptiveSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool confirmsDismissal = false,
}) {
  if (AppPlatform.useCupertino) {
    return Navigator.of(context, rootNavigator: true).push(
      CupertinoModalPopupRoute<T>(
        barrierLabel: CupertinoLocalizations.of(
          context,
        ).modalBarrierDismissLabel,
        barrierColor: CupertinoDynamicColor.resolve(
          kCupertinoModalBarrierColor,
          context,
        ),
        semanticsDismissible: true,
        builder: (sheetContext) => ScrollDismissibleSheet(
          child: _cupertinoSurface(sheetContext, builder),
        ),
      ),
    );
  }
  if (AppPlatform.useWideWeb(context)) {
    return showDialog<T>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: builder(dialogContext),
        ),
      ),
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    enableDrag: !confirmsDismissal,
    backgroundColor: Colors.transparent,
    elevation: 0,
    builder: (sheetContext) => ScrollDismissibleSheet(
      child: Container(
        decoration: BoxDecoration(
          color: AdaptiveColors.modalSurface(sheetContext),
          borderRadius: AppRadius.sheet,
        ),
        child: SafeArea(top: false, child: builder(sheetContext)),
      ),
    ),
  );
}

Widget _cupertinoSurface(BuildContext context, WidgetBuilder builder) {
  if (!AdaptiveGlass.isEnabled(context)) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: AppRadius.sheet,
      ),
      child: _cupertinoContent(context, builder),
    );
  }
  return AdaptiveGlass(
    tint: AdaptiveColors.glassSheetTint(context),
    child: _cupertinoContent(context, builder),
  );
}

Widget _cupertinoContent(BuildContext context, WidgetBuilder builder) {
  return SafeArea(top: false, child: builder(context));
}
