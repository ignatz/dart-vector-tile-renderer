import 'dart:ui';

import 'geometry_model.dart';
import 'simplify.dart';

Path createLine(TileLine line) {
  //final points = ring.points;
  final points = simplifyPoints(
    points: line.points,
    tolerance: tolerance,
    highQuality: true,
  );
  return Path()..addPolygon(points, false);
}

const double tolerance = 25;

Path createPolygon(TilePolygon polygon) {
  final path = Path()..fillType = PathFillType.evenOdd;
  for (final ring in polygon.rings) {
    //final points = ring.points;
    final points = simplifyPoints(
      points: ring.points,
      tolerance: tolerance,
      highQuality: true,
    );

    if (points.length >= 3) {
      path.addPolygon(points, true);
    }
  }
  return path;
}
