import 'dart:ui';
import 'dart:math';

import 'package:collection/collection.dart';

typedef TilePoint = Offset;

extension Point on TilePoint {
  double get x => this.dx;
  double get y => this.dy;

  double distanceSq(TilePoint rhs) {
    final double dx = this.dx - rhs.dx;
    final double dy = this.dy - rhs.dy;
    return dx * dx + dy * dy;
  }
}

class RectangleDouble {
  final double left;
  final double top;
  final double width;
  final double height;

  /// The x-coordinate of the right edge.
  double get right => left + width;

  /// The y-coordinate of the bottom edge.
  double get bottom => top + height;

  const RectangleDouble(this.left, this.top, double width, double height)
      : width = (width < 0)
            ? (width == double.negativeInfinity ? 0.0 : (-width * 0)) as dynamic
            : (width + 0 as dynamic), // Inline _clampToZero<num>.
        height = (height < 0)
            ? (height == double.negativeInfinity ? 0.0 : (-height * 0))
                as dynamic
            : (height + 0 as dynamic);

  RectangleDouble.fromRectangle(Rectangle<double> r)
      : left = r.left,
        top = r.top,
        width = r.width,
        height = r.height;

  factory RectangleDouble.fromPoints(TilePoint a, TilePoint b) {
    double left = min(a.x, b.x);
    double width = (max(a.x, b.x) - left);
    double top = min(a.y, b.y);
    double height = (max(a.y, b.y) - top);
    return RectangleDouble(left, top, width, height);
  }

  /// Tests whether `this` entirely contains [another].
  bool containsRectangle(RectangleDouble another) {
    return left <= another.left &&
        left + width >= another.left + another.width &&
        top <= another.top &&
        top + height >= another.top + another.height;
  }

  /// Tests whether [another] is inside or along the edges of `this`.
  bool containsPoint(TilePoint another) {
    return another.x >= left &&
        another.x <= left + width &&
        another.y >= top &&
        another.y <= top + height;
  }

  bool intersects(RectangleDouble other) {
    return (left <= other.left + other.width &&
        other.left <= left + width &&
        top <= other.top + other.height &&
        other.top <= top + height);
  }
}

typedef Bounds = RectangleDouble;

class TileLine {
  final List<TilePoint> points;
  Bounds? _bounds;

  TileLine(this.points);

  Bounds bounds() {
    var bounds = _bounds;
    if (bounds == null) {
      var minX = double.infinity;
      var maxX = double.negativeInfinity;
      var minY = double.infinity;
      var maxY = double.negativeInfinity;
      for (final point in points) {
        minX = min(minX, point.x);
        maxX = max(maxX, point.x);
        minY = min(minY, point.y);
        maxY = max(maxY, point.y);
      }
      bounds = Bounds.fromPoints(TilePoint(minX, minY), TilePoint(maxX, maxY));
      _bounds = bounds;
    }
    return bounds;
  }

  @override
  bool operator ==(Object other) =>
      other is TileLine && _equality.equals(points, other.points);

  @override
  int get hashCode => _equality.hash(points);

  @override
  String toString() => "TileLine($points)";
}

class TilePolygon {
  final List<TileLine> rings;

  TilePolygon(this.rings);

  Bounds bounds() => rings.first.bounds();

  @override
  bool operator ==(Object other) =>
      other is TilePolygon && _equality.equals(rings, other.rings);

  @override
  int get hashCode => _equality.hash(rings);

  @override
  String toString() => "TilePolygon($rings)";
}

const _equality = ListEquality();
