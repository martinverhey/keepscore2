import 'dart:math';
import 'dart:ui';

extension OffsetListSmoothPath on List<Offset> {
  Path smoothPath() {
    final path = Path()..moveTo(first.dx, first.dy);
    final tangents = _monotoneTangents(this);

    for (var i = 0; i < length - 1; i++) {
      final from = this[i];
      final to = this[i + 1];
      final reach = (to.dx - from.dx) / 3;
      path.cubicTo(
        from.dx + reach,
        from.dy + tangents[i] * reach,
        to.dx - reach,
        to.dy - tangents[i + 1] * reach,
        to.dx,
        to.dy,
      );
    }

    return path;
  }
}

const double _tangentLimit = 3;

List<double> _monotoneTangents(List<Offset> offsets) {
  final slopes = [
    for (var i = 0; i < offsets.length - 1; i++)
      (offsets[i + 1].dy - offsets[i].dy) / (offsets[i + 1].dx - offsets[i].dx),
  ];
  final tangents = [
    slopes.first,
    for (var i = 1; i < slopes.length; i++)
      slopes[i - 1] * slopes[i] <= 0 ? 0.0 : (slopes[i - 1] + slopes[i]) / 2,
    slopes.last,
  ];

  for (var i = 0; i < slopes.length; i++) {
    if (slopes[i] == 0) {
      tangents[i] = 0;
      tangents[i + 1] = 0;
      continue;
    }
    final before = tangents[i] / slopes[i];
    final after = tangents[i + 1] / slopes[i];
    final overshoot = sqrt(before * before + after * after);
    if (overshoot > _tangentLimit) {
      tangents[i] = _tangentLimit / overshoot * before * slopes[i];
      tangents[i + 1] = _tangentLimit / overshoot * after * slopes[i];
    }
  }

  return tangents;
}
