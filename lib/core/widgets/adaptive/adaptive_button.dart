import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';
import 'adaptive_button_kind.enum.dart';
import 'adaptive_colors.dart';
import 'app_platform.dart';

export 'adaptive_button_kind.enum.dart';

class AdaptiveButton extends StatelessWidget {
  const AdaptiveButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = AdaptiveButtonKind.filled,
    this.icon,
    this.busy = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AdaptiveButtonKind kind;
  final Widget? icon;
  final bool busy;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    return AppPlatform.useCupertino
        ? _cupertino(context, enabled)
        : _material(context, enabled);
  }

  Widget _child(Color spinnerColor) {
    if (busy) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: spinnerColor),
      );
    }
    if (icon == null) return Text(label);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon!,
        const SizedBox(width: AppSpacing.sm),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _material(BuildContext context, bool enabled) {
    return expand
        ? SizedBox(
            width: double.infinity,
            child: _materialButton(context, enabled),
          )
        : _materialButton(context, enabled);
  }

  Widget _materialButton(BuildContext context, bool enabled) {
    final scheme = Theme.of(context).colorScheme;
    final callback = enabled ? onPressed : null;
    final size = expand ? const Size.fromHeight(52) : null;

    return switch (kind) {
      AdaptiveButtonKind.filled => FilledButton(
        onPressed: callback,
        style: FilledButton.styleFrom(minimumSize: size),
        child: _child(scheme.onPrimary),
      ),
      AdaptiveButtonKind.tinted => FilledButton.tonal(
        onPressed: callback,
        style: FilledButton.styleFrom(minimumSize: size),
        child: _child(scheme.onSecondaryContainer),
      ),
      AdaptiveButtonKind.plain => TextButton(
        onPressed: callback,
        style: TextButton.styleFrom(minimumSize: size),
        child: _child(scheme.primary),
      ),
      AdaptiveButtonKind.destructive => FilledButton(
        onPressed: callback,
        style: FilledButton.styleFrom(
          minimumSize: size,
          backgroundColor: scheme.errorContainer,
          foregroundColor: scheme.onErrorContainer,
        ),
        child: _child(scheme.onErrorContainer),
      ),
    };
  }

  Widget _cupertino(BuildContext context, bool enabled) {
    return expand
        ? SizedBox(
            width: double.infinity,
            child: _cupertinoButton(context, enabled),
          )
        : _cupertinoButton(context, enabled);
  }

  Widget _cupertinoButton(BuildContext context, bool enabled) {
    final callback = enabled ? onPressed : null;
    final accent = AdaptiveColors.accent(context);
    final sizeStyle = expand
        ? CupertinoButtonSize.large
        : CupertinoButtonSize.medium;

    return switch (kind) {
      AdaptiveButtonKind.filled => CupertinoButton.filled(
        onPressed: callback,
        sizeStyle: sizeStyle,
        child: _child(CupertinoColors.white),
      ),
      AdaptiveButtonKind.tinted => CupertinoButton(
        color: accent.withValues(alpha: AppOpacity.tintedButtonFill),
        onPressed: callback,
        sizeStyle: sizeStyle,
        child: DefaultTextStyle.merge(
          style: TextStyle(color: accent),
          child: _child(accent),
        ),
      ),
      AdaptiveButtonKind.plain => CupertinoButton(
        onPressed: callback,
        sizeStyle: sizeStyle,
        child: _child(accent),
      ),
      AdaptiveButtonKind.destructive => CupertinoButton(
        onPressed: callback,
        sizeStyle: sizeStyle,
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: CupertinoColors.destructiveRed),
          child: _child(CupertinoColors.destructiveRed),
        ),
      ),
    };
  }
}
