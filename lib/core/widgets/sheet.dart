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
    this.fillsHeight = false,
    this.primaryButton,
    this.secondaryButton,
  });

  final Widget? header;
  final String? title;
  final Color? titleColor;
  final String? subtitle;
  final Widget content;
  final bool fillsHeight;
  final Widget? primaryButton;
  final Widget? secondaryButton;

  bool get _hasHeader => header != null || title != null || subtitle != null;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * _maxHeightFraction;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: fillsHeight ? maxHeight : 0,
          maxHeight: maxHeight,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: fillsHeight ? MainAxisSize.max : MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_hasHeader) _header(),
              Flexible(
                fit: fillsHeight ? FlexFit.tight : FlexFit.loose,
                child: _scrollView(context),
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

  Widget _scrollView(BuildContext context) {
    if (!fillsHeight) return _scrollable(context, content);

    return LayoutBuilder(
      builder: (context, constraints) =>
          _scrollable(context, _filledContent(constraints.maxHeight)),
    );
  }

  Widget _scrollable(BuildContext context, Widget child) {
    return SingleChildScrollView(
      physics: ScrollDismissScope.physicsOf(context),
      padding: EdgeInsets.only(top: _contentTopInset),
      child: child,
    );
  }

  Widget _filledContent(double availableHeight) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: (availableHeight - _contentTopInset).clamp(
          0,
          double.infinity,
        ),
      ),
      child: content,
    );
  }

  double get _contentTopInset => _hasHeader ? AppSpacing.lg : 0;

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

const _maxHeightFraction = 0.85;
