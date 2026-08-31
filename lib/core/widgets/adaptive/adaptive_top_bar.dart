import 'package:flutter/widgets.dart';

import '../../theme/app_tokens.dart';
import 'adaptive_colors.dart';
import 'adaptive_glass.dart';

class AdaptiveTopBar extends StatelessWidget {
  const AdaptiveTopBar({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
  });

  final String title;
  final Widget? leading;
  final Widget? trailing;

  static const double inset = AppGlass.topBarHeight + AppGlass.barMargin;

  static double bandHeightOf(BuildContext context) =>
      MediaQuery.paddingOf(context).top + inset + AppGlass.scrollEdgeFade;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: bandHeightOf(context),
      child: Stack(
        children: [
          Positioned.fill(child: _scrollEdge(context)),
          Positioned(
            top: MediaQuery.paddingOf(context).top,
            left: AppGlass.barMargin,
            right: AppGlass.barMargin,
            height: AppGlass.topBarHeight,
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
        Expanded(child: _title()),
        ?trailing,
      ],
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
