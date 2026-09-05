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

class RatingTrendChart extends StatefulWidget {
  const RatingTrendChart({super.key, required this.points});

  final List<RatingPoint> points;

  static const double height = 156;

  @override
  State<RatingTrendChart> createState() => _RatingTrendChartState();
}

class _RatingTrendChartState extends State<RatingTrendChart> {
  int? _focused;

  @override
  Widget build(BuildContext context) {
    if (widget.points.length < 2) {
      return const SizedBox(height: RatingTrendChart.height);
    }

    return SizedBox(
      height: RatingTrendChart.height,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) => _chart(
          context,
          _TrendGeometry(
            widget.points,
            Size(constraints.maxWidth, RatingTrendChart.height),
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
          startLabel: widget.points.first.playedAt.shortDayLabel(context),
          endLabel: widget.points.last.playedAt.shortDayLabel(context),
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
    required this.startLabel,
    required this.endLabel,
    required this.focused,
    required this.progress,
  });

  final List<RatingPoint> points;
  final Color trendColor;
  final Color gridColor;
  final Color guideColor;
  final Color coreColor;
  final String startLabel;
  final String endLabel;
  final int? focused;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final geometry = _TrendGeometry(points, size);
    _paintGrid(canvas, geometry);
    _paintDates(canvas, geometry);

    final line = geometry.offsets.smoothPath();
    final reveal = _sideInset + geometry.plotWidth * progress;

    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, 0, reveal + _sideInset, size.height));
    _paintArea(canvas, geometry, line);
    _paintLine(canvas, line);
    canvas.restore();

    _paintPoints(canvas, geometry, reveal);
    _paintFocus(canvas, geometry);
  }

  void _paintGrid(Canvas canvas, _TrendGeometry geometry) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = _hairline;

    for (final line in geometry.gridLines) {
      _paintDashes(
        canvas,
        Offset(0, line.y),
        Offset(geometry.plotRight, line.y),
        paint,
      );
      final label = _label(line.label)..layout();
      label.paint(
        canvas,
        Offset(geometry.plotRight + AppSpacing.sm, line.y - label.height / 2),
      );
    }
  }

  void _paintDates(Canvas canvas, _TrendGeometry geometry) {
    final baseline = geometry.plotBottom + AppSpacing.xs;
    final start = _label(startLabel)..layout();
    start.paint(canvas, Offset(_sideInset, baseline));

    final end = _label(endLabel)..layout();
    end.paint(
      canvas,
      Offset(geometry.plotRight - _sideInset - end.width, baseline),
    );
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
                _topInset,
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

  void _paintFocus(Canvas canvas, _TrendGeometry geometry) {
    final index = focused;
    if (index == null) return;

    final anchor = geometry.offsets[index];
    _paintDashes(
      canvas,
      Offset(anchor.dx, _topInset),
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
      oldDelegate.startLabel != startLabel ||
      oldDelegate.endLabel != endLabel ||
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
    final origin = span < 1 ? lowest - range / 2 : lowest;

    final bottom = size.height - _dateBandHeight;
    final plotHeight = bottom - _topInset;
    final plotWidth = size.width - _valueGutter - _sideInset * 2;
    final step = plotWidth / (points.length - 1);

    return _TrendGeometry._(
      offsets: [
        for (var i = 0; i < ratings.length; i++)
          Offset(
            _sideInset + step * i,
            bottom - (ratings[i] - origin) / range * plotHeight,
          ),
      ],
      gridLines: span < 1
          ? [(y: (bottom + _topInset) / 2, label: highest.ratingLabel)]
          : [
              (y: _topInset, label: highest.ratingLabel),
              (y: bottom, label: lowest.ratingLabel),
            ],
      plotWidth: plotWidth,
      plotBottom: bottom,
      plotRight: size.width - _valueGutter,
      step: step,
    );
  }

  const _TrendGeometry._({
    required this.offsets,
    required this.gridLines,
    required this.plotWidth,
    required this.plotBottom,
    required this.plotRight,
    required this.step,
  });

  final List<Offset> offsets;
  final List<({double y, String label})> gridLines;
  final double plotWidth;
  final double plotBottom;
  final double plotRight;
  final double step;

  int indexAt(double dx) {
    if (step <= 0) return 0;
    return ((dx - _sideInset) / step).round().clamp(0, offsets.length - 1);
  }
}

const double _topInset = 14;
const double _dateBandHeight = 20;
const double _valueGutter = 46;
const double _sideInset = 4;
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
