import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_tokens.dart';
import 'app_platform.dart';

class AdaptiveTextField extends StatelessWidget {
  const AdaptiveTextField({
    super.key,
    required this.label,
    this.controller,
    this.hintText,
    this.errorText,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.autofillHints,
    this.maxLength,
    this.autofocus = false,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.accentColor,
    this.labelFontWeight,
  });

  final String label;
  final TextEditingController? controller;
  final String? hintText;
  final String? errorText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final int? maxLength;
  final bool autofocus;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Color? accentColor;
  final FontWeight? labelFontWeight;

  @override
  Widget build(BuildContext context) {
    return AppPlatform.useCupertino ? _cupertino(context) : _material();
  }

  Widget _material() {
    final accentBorder = accentColor == null
        ? null
        : OutlineInputBorder(
            borderRadius: AppRadius.card,
            borderSide: BorderSide(
              color: accentColor!.withValues(alpha: AppOpacity.fieldBorder),
            ),
          );

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      autofillHints: autofillHints,
      maxLength: maxLength,
      autofocus: autofocus,
      enabled: enabled,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        errorText: errorText,
        counterText: '',
        filled: accentColor != null,
        fillColor: accentColor?.withValues(alpha: AppOpacity.surfaceFill),
        labelStyle: accentColor == null && labelFontWeight == null
            ? null
            : TextStyle(color: accentColor, fontWeight: labelFontWeight),
        border: accentBorder,
        enabledBorder: accentBorder,
        focusedBorder: accentColor == null
            ? null
            : OutlineInputBorder(
                borderRadius: AppRadius.card,
                borderSide: BorderSide(color: accentColor!, width: 2),
              ),
      ),
    );
  }

  Widget _cupertino(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _cupertinoLabel(context),
        _cupertinoField(context),
        if (errorText != null) _cupertinoErrorText(),
      ],
    );
  }

  Widget _cupertinoLabel(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppSpacing.xs,
        left: AppSpacing.xs,
      ),
      child: Text(
        label,
        style: CupertinoTheme.of(context).textTheme.tabLabelTextStyle.copyWith(
          fontSize: AppTypography.labelLargeSize,
          color: accentColor,
          fontWeight: labelFontWeight,
        ),
      ),
    );
  }

  Widget _cupertinoField(BuildContext context) {
    return CupertinoTextField(
      controller: controller,
      placeholder: hintText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      autofillHints: autofillHints,
      maxLength: maxLength,
      autofocus: autofocus,
      enabled: enabled,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      padding: const EdgeInsets.all(AppSpacing.md - 2),
      decoration: BoxDecoration(
        color:
            accentColor?.withValues(alpha: AppOpacity.surfaceFill) ??
            CupertinoColors.tertiarySystemFill.resolveFrom(context),
        borderRadius: AppRadius.card,
        border: errorText != null
            ? Border.all(color: CupertinoColors.destructiveRed)
            : accentColor == null
            ? null
            : Border.all(
                color: accentColor!.withValues(alpha: AppOpacity.fieldBorder),
              ),
      ),
    );
  }

  Widget _cupertinoErrorText() {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs, left: AppSpacing.xs),
      child: Text(
        errorText!,
        style: const TextStyle(
          color: CupertinoColors.destructiveRed,
          fontSize: AppTypography.labelLargeSize,
        ),
      ),
    );
  }
}
