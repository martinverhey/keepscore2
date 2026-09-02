import 'package:flutter/widgets.dart';

import '../theme/app_tokens.dart';
import 'help_text.dart';
import 'scroll_dismiss_scope.dart';

class Sheet extends StatelessWidget {
  const Sheet({
    super.key,
    this.header,
    this.title,
    this.titleColor,
    this.subtitle,
    required this.content,
    this.primaryButton,
    this.secondaryButton,
  });

  final Widget? header;
  final String? title;
  final Color? titleColor;
  final String? subtitle;
  final Widget content;
  final Widget? primaryButton;
  final Widget? secondaryButton;

  bool get _hasHeader => header != null || title != null || subtitle != null;

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
              if (_hasHeader) _header(),
              Flexible(
                child: SingleChildScrollView(
                  physics: ScrollDismissScope.physicsOf(context),
                  padding: EdgeInsets.only(top: _hasHeader ? AppSpacing.lg : 0),
                  child: content,
                ),
              ),
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

  Widget _header() {
    if (header case final header?) return header;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ?_titleWidget(),
        if (subtitle case final subtitle?) ...[
          const SizedBox(height: AppSpacing.xs),
          HelpText(subtitle),
        ],
      ],
    );
  }

  Widget? _titleWidget() {
    if (title == null) return null;
    return Text(
      title!,
      style: AppTypography.sheetTitle.copyWith(color: titleColor),
      overflow: TextOverflow.ellipsis,
    );
  }
}
