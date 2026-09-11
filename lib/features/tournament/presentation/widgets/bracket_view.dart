import 'package:flutter/widgets.dart';

import '../../../../core/extensions/bracket.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../domain/bracket.model.dart';
import 'bracket_match_tile.dart';

class BracketView extends StatelessWidget {
  const BracketView({
    super.key,
    required this.bracket,
    this.onSelect,
    this.myPlayerId,
  });

  static const double tileWidth = 150;
  static const double tileHeight = 52;
  static const double connectorWidth = 20;
  static const double _gap = AppSpacing.sm;

  final Bracket bracket;
  final void Function(TournamentMatch match)? onSelect;
  final String? myPlayerId;

  static const double _unit = tileHeight + _gap;

  static double _pitch(int round) => (1 << round) * _unit;

  static double _offset(int round) => ((1 << round) - 1) * _unit / 2;

  @override
  Widget build(BuildContext context) {
    if (bracket.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _labels(context),
          const SizedBox(height: AppSpacing.sm),
          _columns(context),
        ],
      ),
    );
  }

  Widget _labels(BuildContext context) {
    return Row(
      children: [
        for (var round = 0; round < bracket.roundCount; round++) ...[
          if (round > 0) const SizedBox(width: connectorWidth),
          SizedBox(
            width: tileWidth,
            child: Text(
              bracket.roundLabel(context, round + 1),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.captionStrong,
            ),
          ),
        ],
      ],
    );
  }

  Widget _columns(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var round = 0; round < bracket.roundCount; round++) ...[
          if (round > 0) _connectors(context, round - 1),
          _round(round),
        ],
      ],
    );
  }

  Widget _round(int round) {
    final matches = bracket.rounds[round];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: _offset(round)),
        for (var index = 0; index < matches.length; index++) ...[
          if (index > 0) SizedBox(height: _pitch(round) - tileHeight),
          BracketMatchTile(
            match: matches[index],
            width: tileWidth,
            height: tileHeight,
            onTap: _tapHandler(matches[index]),
            myPlayerId: myPlayerId,
          ),
        ],
      ],
    );
  }

  VoidCallback? _tapHandler(TournamentMatch match) {
    final select = onSelect;
    if (select == null || !match.isPlayable) return null;
    return () => select(match);
  }

  Widget _connectors(BuildContext context, int round) {
    final parents = bracket.rounds[round + 1].length;
    final pitch = _pitch(round);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: _offset(round) + tileHeight / 2),
        for (var index = 0; index < parents; index++) ...[
          if (index > 0) SizedBox(height: pitch),
          CustomPaint(
            size: Size(connectorWidth, pitch),
            painter: _ConnectorPainter(color: _lineColor),
          ),
        ],
      ],
    );
  }

  static Color get _lineColor =>
      AppColors.neutral.withValues(alpha: AppOpacity.controlBorder);
}

class _ConnectorPainter extends CustomPainter {
  const _ConnectorPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final midX = size.width / 2;
    final midY = size.height / 2;

    canvas
      ..drawLine(Offset.zero, Offset(midX, 0), paint)
      ..drawLine(Offset(0, size.height), Offset(midX, size.height), paint)
      ..drawLine(Offset(midX, 0), Offset(midX, size.height), paint)
      ..drawLine(Offset(midX, midY), Offset(size.width, midY), paint);
  }

  @override
  bool shouldRepaint(_ConnectorPainter oldDelegate) =>
      oldDelegate.color != color;
}
