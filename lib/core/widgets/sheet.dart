import 'package:flutter/widgets.dart';

import '../theme/app_tokens.dart';
import 'adaptive/adaptive_colors.dart';
import 'adaptive/adaptive_glass.dart';
import 'help_text.dart';
import 'scroll_dismiss_scope.dart';

class Sheet extends StatelessWidget {
  static const double _pinnedHeaderGap = AppSpacing.md;
  static const double _scrollingHeaderGap = AppSpacing.lg - _pinnedHeaderGap;

  const Sheet({
    super.key,
    this.header,
    this.title,
    this.titleColor,
    this.titleTrailing,
    this.titleTrailingAlignment = CrossAxisAlignment.baseline,
    this.subtitle,
    required this.content,
    this.fillsHeight = false,
    this.primaryButton,
    this.secondaryButton,
  });

  final Widget? header;
  final String? title;
  final Color? titleColor;
  final Widget? titleTrailing;
  final CrossAxisAlignment titleTrailingAlignment;
  final String? subtitle;
  final Widget content;
  final bool fillsHeight;
  final Widget? primaryButton;
  final Widget? secondaryButton;

  bool get _hasHeader => header != null || title != null || subtitle != null;

  bool get _hasButtons => primaryButton != null || secondaryButton != null;

  @override
  Widget build(BuildContext context) {
    final bottomInset = AppSpacing.lg + MediaQuery.paddingOf(context).bottom;
    final maxHeight =
        MediaQuery.sizeOf(context).height * _maxHeightFraction +
        MediaQuery.paddingOf(context).bottom;
    final scrollsUnderHeader =
        _hasHeader && header == null && AdaptiveGlass.isEnabled(context);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: fillsHeight ? maxHeight : 0,
          maxHeight: maxHeight,
        ),
        child: Padding(
          padding: EdgeInsets.only(
            top: scrollsUnderHeader ? 0 : AppSpacing.lg,
            bottom: _hasButtons ? bottomInset : 0,
          ),
          child: Column(
            mainAxisSize: fillsHeight ? MainAxisSize.max : MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_hasHeader && !scrollsUnderHeader) ...[
                _inset(_header()),
                const SizedBox(height: _pinnedHeaderGap),
              ],
              Flexible(
                fit: fillsHeight ? FlexFit.tight : FlexFit.loose,
                child: scrollsUnderHeader
                    ? _scrollUnderHeader(context, bottomInset)
                    : _scrollView(context, _contentPadding(bottomInset)),
              ),
              if (primaryButton != null) ...[
                const SizedBox(height: AppSpacing.lg),
                _inset(primaryButton!),
              ],
              if (secondaryButton != null) ...[
                const SizedBox(height: AppSpacing.sm),
                _inset(secondaryButton!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _inset(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: child,
    );
  }

  Widget _scrollUnderHeader(BuildContext context, double bottomInset) {
    return CustomScrollView(
      physics: ScrollDismissScope.physicsOf(context),
      shrinkWrap: !fillsHeight,
      slivers: [
        PinnedHeaderSliver(child: _headerOverContent(context)),
        SliverPadding(
          padding: _contentPadding(bottomInset),
          sliver: _contentSliver(),
        ),
      ],
    );
  }

  Widget _headerOverContent(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: _headerScrollEdge(context)),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            _pinnedHeaderGap,
          ),
          child: _header(),
        ),
      ],
    );
  }

  Widget _headerScrollEdge(BuildContext context) {
    return IgnorePointer(
      child: ClipRRect(
        borderRadius: AppRadius.sheet,
        child: LiquidGlassScrollEdge(
          edge: LiquidGlassEdge.top,
          color: AdaptiveColors.glassSheetTint(context),
        ),
      ),
    );
  }

  Widget _contentSliver() {
    if (fillsHeight) {
      return SliverFillRemaining(hasScrollBody: false, child: content);
    }
    return SliverToBoxAdapter(child: content);
  }

  EdgeInsets _contentPadding(double bottomInset) {
    return EdgeInsets.fromLTRB(
      AppSpacing.lg,
      _hasHeader ? _scrollingHeaderGap : 0,
      AppSpacing.lg,
      _hasButtons ? 0 : bottomInset,
    );
  }

  Widget _scrollView(BuildContext context, EdgeInsets padding) {
    if (!fillsHeight) return _scrollable(context, padding, content);

    return LayoutBuilder(
      builder: (context, constraints) => _scrollable(
        context,
        padding,
        _filledContent(constraints.maxHeight - padding.vertical),
      ),
    );
  }

  Widget _scrollable(BuildContext context, EdgeInsets padding, Widget child) {
    return SingleChildScrollView(
      physics: ScrollDismissScope.physicsOf(context),
      padding: padding,
      child: child,
    );
  }

  Widget _filledContent(double availableHeight) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: availableHeight.clamp(0, double.infinity),
      ),
      child: content,
    );
  }

  Widget _header() {
    if (header case final header?) return header;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ?_titleRow(),
        if (subtitle case final subtitle?) ...[
          const SizedBox(height: AppSpacing.xs),
          HelpText(subtitle),
        ],
      ],
    );
  }

  Widget? _titleRow() {
    if (title == null) return null;
    if (titleTrailing case final trailing?) {
      return Row(
        crossAxisAlignment: titleTrailingAlignment,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(child: _title()),
          trailing,
        ],
      );
    }

    return _title();
  }

  Widget _title() {
    return Text(
      title!,
      style: AppTypography.sheetTitle.copyWith(color: titleColor),
      overflow: TextOverflow.ellipsis,
    );
  }
}

const _maxHeightFraction = 0.85;
