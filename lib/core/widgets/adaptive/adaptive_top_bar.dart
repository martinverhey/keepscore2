import 'package:flutter/widgets.dart';

import '../../theme/app_tokens.dart';
import 'adaptive_colors.dart';
import 'adaptive_glass.dart';

class AdaptiveTopBar extends StatelessWidget {
  const AdaptiveTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
  });

  final String title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;

  static const double inset = AppGlass.topBarHeight + AppGlass.barMargin;

  static double insetFor({required bool hasSubtitle}) =>
      barHeightFor(hasSubtitle: hasSubtitle) + AppGlass.barMargin;

  static double barHeightFor({required bool hasSubtitle}) =>
      hasSubtitle ? AppGlass.topBarSubtitleHeight : AppGlass.topBarHeight;

  static double bandHeightOf(
    BuildContext context, {
    bool hasSubtitle = false,
  }) =>
      MediaQuery.paddingOf(context).top +
      insetFor(hasSubtitle: hasSubtitle) +
      AppGlass.scrollEdgeFade;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: bandHeightOf(context, hasSubtitle: subtitle != null),
      child: Stack(
        children: [
          Positioned.fill(child: _scrollEdge(context)),
          Positioned(
            top: MediaQuery.paddingOf(context).top,
            left: AppGlass.barMargin,
            right: AppGlass.barMargin,
            height: barHeightFor(hasSubtitle: subtitle != null),
            child: _row(),
          ),
        ],
      ),
    );
  }

  Widget _scrollEdge(BuildContext context) {
    return IgnorePointer(
      child: LiquidGlassScrollEdge(
        edge: LiquidGlassEdge.top,
        color: AdaptiveColors.scrollEdgeTint(context),
      ),
    );
  }

  Widget _row() {
    return Row(
      spacing: AppSpacing.sm,
      children: [
        ?leading,
        Expanded(child: _titleColumn()),
        ?trailing,
      ],
    );
  }

  Widget _titleColumn() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_title(), ?subtitle],
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
}
