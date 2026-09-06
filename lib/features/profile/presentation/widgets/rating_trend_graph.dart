import 'dart:math';

import 'package:flutter/widgets.dart';

import '../../../../core/extensions/date_time.extension.dart';
import '../../../../core/extensions/double.extension.dart';
import '../../../../core/extensions/offset_list.extension.dart';
import '../../../../core/extensions/rating_point_list.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/rating_delta.dart';
import '../../domain/rating_point.model.dart';

class RatingTrendGraph extends StatefulWidget {
  const RatingTrendGraph({super.key, required this.points});

  final List<RatingPoint> points;

  static const double height = 126;

  @override
  State<RatingTrendGraph> createState() => _RatingTrendGraphState();
}

class _RatingTrendGraphState extends State<RatingTrendGraph> {
  int? _focused;

  @override
  Widget build(BuildContext context) {
    if (widget.points.length < 2) {
      return const SizedBox(height: RatingTrendGraph.height);
    }

    return SizedBox(
      height: RatingTrendGraph.height,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) => _chart(
          context,
          _TrendGeometry(
            widget.points,
            Size(constraints.maxWidth, RatingTrendGraph.height),
          ),
        ),
      ),
    );
  }

  Widget _chart(BuildContext context, _TrendGeometry geometry) {
    final focused = _focused;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) => _toggleAt(geometry, details.localPosition.dx),
      onHorizontalDragStart: (details) =>
          _focusAt(geometry, details.localPosition.dx),
      onHorizontalDragUpdate: (details) =>
          _focusAt(geometry, details.localPosition.dx),
      child: Stack(
        children: [
          Positioned.fill(child: _graph(context, geometry)),
          if (focused != null)
            Positioned.fill(child: _bubbleLayer(context, geometry, focused)),
        ],
      ),
    );
  }

  Widget _graph(BuildContext context, _TrendGeometry geometry) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, progress, _) => CustomPaint(
        size: Size.infinite,
        painter: _RatingTrendPainter(
          points: widget.points,
          trendColor: widget.points.trendColor(context),
          gridColor: AppColors.neutralSurface,
          guideColor: AppColors.neutral.withValues(
            alpha: AppOpacity.controlBorder,
          ),
          coreColor: AdaptiveColors.modalSurface(context),
          focused: _focused,
          progress: progress,
        ),
      ),
    );
  }

  Widget _bubbleLayer(
    BuildContext context,
    _TrendGeometry geometry,
    int focused,
  ) {
    return IgnorePointer(
      child: CustomSingleChildLayout(
        delegate: _BubbleLayout(geometry.offsets[focused]),
        child: _bubble(context, widget.points[focused]),
      ),
    );
  }

  Widget _bubble(BuildContext context, RatingPoint point) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AdaptiveColors.modalSurface(context),
        borderRadius: AppRadius.card,
        border: Border.all(
          color: widget.points
              .trendColor(context)
              .withValues(alpha: AppOpacity.accentBorder),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _bubbleValue(point),
            Text(
              point.playedAt.shortDayLabel(context),
              style: AppTypography.labelTiny,
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubbleValue(RatingPoint point) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          point.ratingAfter.ratingLabel,
          style: AppTypography.bodySmall.copyWith(
            fontFeatures: AppTypography.tabularFigures,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        RatingDelta(
          value: point.ratingDelta,
          fontSize: AppTypography.labelLargeSize,
        ),
      ],
    );
  }

  void _toggleAt(_TrendGeometry geometry, double dx) {
    final index = geometry.indexAt(dx);
    setState(() => _focused = index == _focused ? null : index);
  }

  void _focusAt(_TrendGeometry geometry, double dx) {
    final index = geometry.indexAt(dx);
    if (index == _focused) return;
    setState(() => _focused = index);
  }
}

class _BubbleLayout extends SingleChildLayoutDelegate {
  const _BubbleLayout(this.anchor);

  final Offset anchor;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final above = anchor.dy - _bubbleGap - childSize.height;
    return Offset(
      min(
        max(anchor.dx - childSize.width / 2, 0),
        max(size.width - childSize.width, 0),
      ),
      above < 0 ? anchor.dy + _bubbleGap : above,
    );
  }

  @override
  bool shouldRelayout(_BubbleLayout oldDelegate) =>
      oldDelegate.anchor != anchor;
}

class _RatingTrendPainter extends CustomPainter {
  _RatingTrendPainter({
    required this.points,
    required this.trendColor,
    required this.gridColor,
    required this.guideColor,
    required this.coreColor,
    required this.focused,
    required this.progress,
  });

  final List<RatingPoint> points;
  final Color trendColor;
  final Color gridColor;
  final Color guideColor;
  final Color coreColor;
  final int? focused;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final geometry = _TrendGeometry(points, size);
    _paintGrid(canvas, geometry);

    final line = geometry.offsets.smoothPath();
    final reveal = geometry.revealAt(progress);

    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, 0, reveal + _sideInset, size.height));
    _paintArea(canvas, geometry, line);
    _paintLine(canvas, line);
    canvas.restore();

    _paintPoints(canvas, geometry, reveal);
    _paintExtremes(canvas, geometry, reveal);
    _paintFocus(canvas, geometry);
  }

  void _paintGrid(Canvas canvas, _TrendGeometry geometry) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = _hairline;

    for (final y in geometry.gridLines) {
      _paintDashes(canvas, Offset(0, y), Offset(geometry.plotRight, y), paint);
    }
  }

  void _paintArea(Canvas canvas, _TrendGeometry geometry, Path line) {
    final area = Path.from(line)
      ..lineTo(geometry.offsets.last.dx, geometry.plotBottom)
      ..lineTo(geometry.offsets.first.dx, geometry.plotBottom)
      ..close();

    canvas.drawPath(
      area,
      Paint()
        ..shader =
            LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                trendColor.withValues(alpha: AppOpacity.badgeFill),
                AppColors.transparent,
              ],
            ).createShader(
              Rect.fromLTRB(
                0,
                geometry.plotTop,
                geometry.plotRight,
                geometry.plotBottom,
              ),
            ),
    );
  }

  void _paintLine(Canvas canvas, Path line) {
    canvas.drawPath(
      line,
      Paint()
        ..color = trendColor.withValues(alpha: AppOpacity.accentFill)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _glowWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, _glowBlur),
    );

    canvas.drawPath(
      line,
      Paint()
        ..color = trendColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = _lineWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _paintPoints(Canvas canvas, _TrendGeometry geometry, double reveal) {
    final fill = Paint()..color = trendColor;
    final offsets = geometry.offsets;

    for (var i = 0; i < offsets.length; i++) {
      if (offsets[i].dx > reveal) continue;
      if (i == offsets.length - 1) {
        _paintMarker(canvas, offsets[i]);
      } else {
        canvas.drawCircle(offsets[i], _dotRadius, fill);
      }
    }
  }

  void _paintExtremes(Canvas canvas, _TrendGeometry geometry, double reveal) {
    for (final extreme in geometry.extremes) {
      final anchor = geometry.offsets[extreme.index];
      if (anchor.dx > reveal) continue;

      final label = _label(extreme.label)..layout();
      label.paint(
        canvas,
        Offset(
          extreme.isHighest
              ? geometry.plotRight - _sideInset - label.width
              : _sideInset,
          extreme.isHighest
              ? anchor.dy - _valueLabelGap - label.height
              : anchor.dy + _valueLabelGap,
        ),
      );
    }
  }

  void _paintFocus(Canvas canvas, _TrendGeometry geometry) {
    final index = focused;
    if (index == null) return;

    final anchor = geometry.offsets[index];
    _paintDashes(
      canvas,
      Offset(anchor.dx, geometry.plotTop),
      Offset(anchor.dx, geometry.plotBottom),
      Paint()
        ..color = guideColor
        ..strokeWidth = _hairline,
    );
    _paintMarker(canvas, anchor);
  }

  void _paintMarker(Canvas canvas, Offset center) {
    canvas.drawCircle(
      center,
      _markerHaloRadius,
      Paint()..color = trendColor.withValues(alpha: AppOpacity.accentFill),
    );
    canvas.drawCircle(center, _markerRadius, Paint()..color = trendColor);
    canvas.drawCircle(center, _markerCoreRadius, Paint()..color = coreColor);
  }

  void _paintDashes(Canvas canvas, Offset from, Offset to, Paint paint) {
    final total = (to - from).distance;
    if (total <= 0) return;
    final direction = (to - from) / total;

    for (var travelled = 0.0; travelled < total; travelled += _dashPitch) {
      canvas.drawLine(
        from + direction * travelled,
        from + direction * min(travelled + _dashLength, total),
        paint,
      );
    }
  }

  TextPainter _label(String text) => TextPainter(
    text: TextSpan(text: text, style: AppTypography.labelTiny),
    textDirection: TextDirection.ltr,
  );

  @override
  bool shouldRepaint(covariant _RatingTrendPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.trendColor != trendColor ||
      oldDelegate.gridColor != gridColor ||
      oldDelegate.guideColor != guideColor ||
      oldDelegate.coreColor != coreColor ||
      oldDelegate.focused != focused ||
      oldDelegate.progress != progress;
}

class _TrendGeometry {
  factory _TrendGeometry(List<RatingPoint> points, Size size) {
    final ratings = [for (final point in points) point.ratingAfter];
    final lowest = ratings.reduce(min);
    final highest = ratings.reduce(max);
    final span = highest - lowest;
    final range = span < 1 ? 1.0 : span;
    final origin = lowest - (range - span) / 2;

    final top = _valueBand;
    final bottom = size.height - _valueBand;
    final plotHeight = bottom - top;
    final plotWidth = size.width - _sideInset * 2;
    final step = plotWidth / (points.length - 1);

    final offsets = [
      for (var i = 0; i < ratings.length; i++)
        Offset(
          _sideInset + step * i,
          bottom - (ratings[i] - origin) / range * plotHeight,
        ),
    ];
    final highestIndex = ratings.indexOf(highest);
    final lowestIndex = ratings.indexOf(lowest);

    return _TrendGeometry._(
      offsets: offsets,
      gridLines: [
        offsets[highestIndex].dy,
        if (lowestIndex != highestIndex) offsets[lowestIndex].dy,
      ],
      extremes: [
        (index: highestIndex, label: highest.ratingLabel, isHighest: true),
        if (lowestIndex != highestIndex)
          (index: lowestIndex, label: lowest.ratingLabel, isHighest: false),
      ],
      plotTop: top,
      plotBottom: bottom,
      plotRight: size.width,
      step: step,
    );
  }

  const _TrendGeometry._({
    required this.offsets,
    required this.gridLines,
    required this.extremes,
    required this.plotTop,
    required this.plotBottom,
    required this.plotRight,
    required this.step,
  });

  final List<Offset> offsets;
  final List<double> gridLines;
  final List<({int index, String label, bool isHighest})> extremes;
  final double plotTop;
  final double plotBottom;
  final double plotRight;
  final double step;

  double revealAt(double progress) =>
      offsets.first.dx + (offsets.last.dx - offsets.first.dx) * progress;

  int indexAt(double dx) {
    if (step <= 0) return 0;
    return ((dx - _sideInset) / step).round().clamp(0, offsets.length - 1);
  }
}

const double _valueLabelHeight = 16;
const double _valueLabelGap = 8;
const double _valueBand = _valueLabelGap + _valueLabelHeight;
const double _sideInset = _markerHaloRadius + 2;
const double _hairline = 1;
const double _lineWidth = 2.5;
const double _glowWidth = 8;
const double _glowBlur = 5;
const double _dotRadius = 2.5;
const double _markerRadius = 4.5;
const double _markerCoreRadius = 2;
const double _markerHaloRadius = 8;
const double _bubbleGap = 12;
const double _dashLength = 3;
const double _dashPitch = 6;
