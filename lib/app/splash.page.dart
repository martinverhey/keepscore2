import 'package:flutter/widgets.dart';

import '../core/theme/app_tokens.dart';
import '../core/widgets/adaptive/adaptive.dart';

const double _wordmarkTop = 146;
const double _scoreIndent = 76;
const double _coreRise = 28;
const double _coreShift = 12;

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(decoration: _background, child: _content());
  }

  Widget _content() {
    return Column(
      children: [
        Expanded(child: _wordmark()),
        const Expanded(child: AdaptiveLoader(color: AppColors.white)),
      ],
    );
  }

  Widget _wordmark() {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          _wordmarkTop,
          AppSpacing.md,
          0,
        ),
        child: DefaultTextStyle(style: AppTypography.brandWord, child: _mark()),
      ),
    );
  }

  Widget _mark() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.topLeft,
      clipBehavior: Clip.none,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [_keep(), _score()],
      ),
    );
  }

  Widget _keep() {
    return const Text.rich(
      TextSpan(
        children: [
          TextSpan(text: 'K', style: AppTypography.brandInitial),
          TextSpan(text: 'eep', style: AppTypography.brandWord),
        ],
      ),
    );
  }

  Widget _score() {
    return Padding(
      padding: const EdgeInsets.only(left: _scoreIndent),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          const Text('S', style: AppTypography.brandInitial),
          Transform.translate(
            offset: const Offset(-_coreShift, -_coreRise),
            child: _coreAndByline(),
          ),
        ],
      ),
    );
  }

  Widget _coreAndByline() {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('core', style: AppTypography.brandWord),
        Text('by Martini', style: AppTypography.brandByline),
      ],
    );
  }

  static const BoxDecoration _background = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [AppColors.splashGradientStart, AppColors.splashGradientEnd],
    ),
  );
}
