import 'dart:ui';

import 'geometry_model.dart';

Path createLine(TileLine line) => Path()..addPolygon(line.points, false);

Path createPolygon(TilePolygon polygon) {
  final path = Path()..fillType = PathFillType.evenOdd;
  for (final ring in polygon.rings) {
    path.addPolygon(ring.points, true);
  }
  return path;
}
