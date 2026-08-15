import 'package:flutter/widgets.dart';

import '../theme/app_tokens.dart';
import 'adaptive/adaptive.dart';
import 'help_text.dart';

class Sheet extends StatelessWidget {
  const Sheet({
    super.key,
    this.title,
    this.titleColor,
    this.subtitle,
    this.avatar,
    this.headerTrailing,
    required this.content,
    this.primaryButton,
    this.secondaryButton,
  });

  final String? title;
  final Color? titleColor;
  final String? subtitle;
  final Widget? avatar;
  final Widget? headerTrailing;
  final Widget content;
  final AdaptiveButton? primaryButton;
  final AdaptiveButton? secondaryButton;

  bool get _hasHeader => title != null || subtitle != null || avatar != null;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_hasHeader) ...[
                _header(context),
                const SizedBox(height: AppSpacing.lg),
              ],
              Flexible(child: SingleChildScrollView(child: content)),
              if (primaryButton != null) ...[
                const SizedBox(height: AppSpacing.lg),
                primaryButton!,
              ],
              if (secondaryButton != null) ...[
                const SizedBox(height: AppSpacing.sm),
                secondaryButton!,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final titleWidget = title == null
        ? null
        : Text(
            title!,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: titleColor,
            ),
            overflow: TextOverflow.ellipsis,
          );
    final subtitleWidget = subtitle == null ? null : HelpText(subtitle!);

    if (avatar == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ?titleWidget,
          if (subtitleWidget != null) ...[
            const SizedBox(height: AppSpacing.xs),
            subtitleWidget,
          ],
        ],
      );
    }

    return Row(
      children: [
        avatar!,
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ?titleWidget,
              if (subtitleWidget != null) ...[
                const SizedBox(height: 2),
                subtitleWidget,
              ],
            ],
          ),
        ),
        if (headerTrailing != null) ...[
          const SizedBox(width: AppSpacing.md),
          headerTrailing!,
        ],
      ],
    );
  }
}
