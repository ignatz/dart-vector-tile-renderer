import 'dart:typed_data';
import 'dart:ui';

import 'package:dart_earcut/dart_earcut.dart';

import 'geometry_model.dart';
import 'geometry_model_ui.dart';

class Tile {
  final List<TileLayer> layers;

  Tile({required this.layers});
}

class TileLayer {
  final String name;
  final int extent;
  final List<TileFeature> features;

  TileLayer({required this.name, required this.extent, required this.features});
}

class BoundedPath {
  final Path path;
  Rect? _bounds;
  List<PathMetric>? _pathMetrics;

  BoundedPath(this.path);

  Rect get bounds {
    var bounds = _bounds;
    if (bounds == null) {
      bounds = path.getBounds();
      _bounds = bounds;
    }
    return bounds;
  }

  List<PathMetric> get pathMetrics {
    var pathMetrics = _pathMetrics;
    if (pathMetrics == null) {
      pathMetrics = path.computeMetrics().toList(growable: false);
      _pathMetrics = pathMetrics;
    }
    return pathMetrics;
  }
}

class TileFeature {
  final TileFeatureType type;
  final Map<String, dynamic> properties;

  // Inputs.
  final List<TilePoint> _modelPoints;
  final List<TileLine> _modelLines;
  final List<TilePolygon> _modelPolygons;

  // Cached values.
  List<BoundedPath>? _paths;
  BoundedPath? _compoundPath;

  TileFeature({
    required this.type,
    required this.properties,
    required List<TilePoint>? points,
    required List<TileLine>? lines,
    required List<TilePolygon>? polygons,
  })  : _modelPoints = points ?? const [],
        _modelLines = lines ?? const [],
        _modelPolygons = polygons ?? const [];

  List<TilePoint> get points {
    assert(type == TileFeatureType.point, 'Feature does not have points');
    return _modelPoints;
  }

  bool get hasPaths =>
      type == TileFeatureType.linestring || type == TileFeatureType.polygon;

  bool get hasPoints => type == TileFeatureType.point;

  BoundedPath get compoundPath {
    return _compoundPath ??= () {
      final paths = this.paths;
      if (paths.length == 1) {
        return paths.first;
      } else {
        final linesPath = Path();
        for (final line in paths) {
          linesPath.addPath(line.path, Offset.zero);
        }
        return BoundedPath(linesPath);
      }
    }();
  }

  List<BoundedPath> get paths {
    assert(
        type != TileFeatureType.point, 'Cannot get paths from a point feature');

    return _paths ??= () {
      return switch (type) {
        TileFeatureType.linestring => _modelLines
            .map((e) => BoundedPath(createLine(e)))
            .toList(growable: false),
        TileFeatureType.polygon => _modelPolygons
            .map((e) => BoundedPath(createPolygon(e)))
            .toList(growable: false),
        _ => throw Exception('type mismatch'),
      };
    }();
  }

  List<int> _getTriangles(List<Offset> points) {
    final ps = List<double>.generate(points.length * 2, (index) {
      if (index.isEven) {
        return points[index ~/ 2].dx;
      }
      return points[index ~/ 2].dy;
    });

    return Earcut.triangulateRaw(ps);
  }

  Vertices? _vertices;
  Vertices get vertices {
    return _vertices ??= () {
      final trianglePoints = <Offset>[];

      for (final polygon in _modelPolygons) {
        for (final ring in polygon.rings) {
          final points = ring.points;
          final triangles = _getTriangles(points);

          final len = triangles.length;
          for (int i = 0; i < len; ++i) {
            trianglePoints.add(points[triangles[i]]);
          }
        }
      }

      final points = Float32List(trianglePoints.length * 2);
      for (int i = 0; i < trianglePoints.length; ++i) {
        points[i * 2] = trianglePoints[i].dx;
        points[i * 2 + 1] = trianglePoints[i].dy;
      }

      return Vertices.raw(VertexMode.triangles, points);
    }();
  }
}

enum TileFeatureType { point, linestring, polygon, background, none }
