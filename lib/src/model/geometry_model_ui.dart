import 'dart:ui';

import 'geometry_model.dart';
import 'simplify.dart';

const double tolerance = 35;
const bool simplify = false;

Path createLine(TileLine line) {
  final points = simplify
      ? simplifyPoints(
          points: line.points,
          tolerance: tolerance,
          highQuality: true,
        )
      : line.points;
  return Path()..addPolygon(points, false);
}

Path createPolygon(TilePolygon polygon) {
  final path = Path()..fillType = PathFillType.evenOdd;
  for (final ring in polygon.rings) {
    final points = simplify
        ? simplifyPoints(
            points: ring.points,
            tolerance: tolerance,
            highQuality: true,
          )
        : ring.points;

    if (points.length >= 3) {
      path.addPolygon(points, true);
    }
  }
  return path;
}
