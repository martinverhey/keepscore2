import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';
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
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(cancelLabel),
              ),
              CupertinoDialogAction(
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
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(cancelLabel),
              ),
              FilledButton(
                style: destructive
                    ? FilledButton.styleFrom(
                        backgroundColor: Theme.of(dialogContext).colorScheme.error,
                        foregroundColor: Theme.of(dialogContext).colorScheme.onError,
                      )
                    : null,
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(confirmLabel),
              ),
            ],
          ),
        );
  return future.then((value) => value ?? false);
}

Future<T?> showAdaptiveSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  if (AppPlatform.useCupertino) {
    return showCupertinoModalPopup<T>(
      context: context,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(sheetContext),
          borderRadius: AppRadius.sheet,
        ),
        child: SafeArea(top: false, child: builder(sheetContext)),
      ),
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: builder,
  );
}
