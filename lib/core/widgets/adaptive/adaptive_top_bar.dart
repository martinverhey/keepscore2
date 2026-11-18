import 'package:flutter/widgets.dart';

import '../../theme/app_tokens.dart';
import 'adaptive_glass.dart';

class AdaptiveTopBar extends StatelessWidget {
  const AdaptiveTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.caption,
    this.leading,
    this.trailing,
    this.onTitleTap,
  });

  final String title;
  final Widget? subtitle;
  final Widget? caption;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTitleTap;

  static const double subtitleTop =
      AppGlass.topBarHeight - AppGlass.topBarSubtitleRise;

  static double subtitleTopFor({required bool hasCaption}) =>
      subtitleTop + (hasCaption ? AppGlass.topBarSubtitleHeight : 0);

  static double insetFor({bool hasSubtitle = false, bool hasCaption = false}) =>
      barHeightFor(hasSubtitle: hasSubtitle, hasCaption: hasCaption) +
      AppGlass.barMargin;

  static double barHeightFor({
    bool hasSubtitle = false,
    bool hasCaption = false,
  }) {
    final lines = (hasSubtitle ? 1 : 0) + (hasCaption ? 1 : 0);
    if (lines == 0) return AppGlass.topBarHeight;
    return AppGlass.topBarHeight +
        lines * AppGlass.topBarSubtitleHeight -
        AppGlass.topBarSubtitleRise;
  }

  static double bandHeightOf(
    BuildContext context, {
    bool hasSubtitle = false,
    bool hasCaption = false,
  }) =>
      MediaQuery.paddingOf(context).top +
      insetFor(hasSubtitle: hasSubtitle, hasCaption: hasCaption) +
      AppGlass.scrollEdgeFade;

  double get _barHeight =>
      barHeightFor(hasSubtitle: subtitle != null, hasCaption: caption != null);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: bandHeightOf(
        context,
        hasSubtitle: subtitle != null,
        hasCaption: caption != null,
      ),
      child: Stack(
        children: [
          Positioned.fill(child: _scrollEdge(context)),
          Positioned(
            top: MediaQuery.paddingOf(context).top,
            left: AppGlass.barMargin,
            right: AppGlass.barMargin,
            height: _barHeight,
            child: _row(),
          ),
          ?_subtitleLine(context),
        ],
      ),
    );
  }

  Widget _scrollEdge(BuildContext context) {
    return IgnorePointer(
      child: LiquidGlassScrollEdge(edge: LiquidGlassEdge.top),
    );
  }

  Widget _row() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.sm,
      children: [
        ?_actionSlot(leading),
        Expanded(child: _tappableTitle()),
        ?_actionSlot(trailing),
      ],
    );
  }

  Widget? _actionSlot(Widget? action) {
    if (action == null) return null;
    return SizedBox(
      height: AppGlass.topBarHeight,
      child: Center(child: action),
    );
  }

  Widget _tappableTitle() {
    return _tappable(_titleColumn());
  }

  Widget _titleColumn() {
    return SizedBox(
      height: _barHeight,
      child: Stack(children: [_titleLine(), ?_captionLine()]),
    );
  }

  Widget _titleLine() {
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      height: AppGlass.topBarHeight,
      child: Align(alignment: Alignment.centerLeft, child: _title()),
    );
  }

  Widget _title() {
    return Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.barTitle,
    );
  }

  Widget? _captionLine() {
    final line = caption;
    if (line == null) return null;
    return _line(top: subtitleTop, child: line);
  }

  Widget _line({required double top, required Widget child}) {
    return Positioned(
      left: 0,
      right: 0,
      top: top,
      height: AppGlass.topBarSubtitleHeight,
      child: Align(alignment: Alignment.topLeft, child: child),
    );
  }

  Widget? _subtitleLine(BuildContext context) {
    final line = subtitle;
    if (line == null) return null;
    return Positioned(
      left: AppGlass.barMargin,
      right: AppGlass.barMargin,
      top:
          MediaQuery.paddingOf(context).top +
          subtitleTopFor(hasCaption: caption != null),
      height: AppGlass.topBarSubtitleHeight,
      child: _tappable(Align(alignment: Alignment.topCenter, child: line)),
    );
  }

  Widget _tappable(Widget child) {
    final onTap = onTitleTap;
    if (onTap == null) return child;
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: child,
      ),
    );
  }
}
