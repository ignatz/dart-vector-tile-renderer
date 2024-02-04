import 'dart:ui' as ui;

import '../../vector_tile_renderer.dart';
import '../context.dart';
import '../themes/expression/expression.dart';
import '../themes/style.dart';
import 'extensions.dart';
import 'feature_renderer.dart';

final List<double> batchedTriangles = [];
ui.Paint? prevPaint;
int batchSize = 0;

class FillRenderer extends FeatureRenderer {
  final Logger logger;
  FillRenderer(this.logger);

  @override
  void render(
    Context context,
    ThemeLayerType layerType,
    Style style,
    TileLayer layer,
    TileFeature feature,
    bool forceFlush,
  ) {
    if (!feature.hasPaths) {
      return;
    }
    if (style.fillPaint == null && style.outlinePaint == null) {
      logger
          .warn(() => 'polygon does not have a fill paint or an outline paint');
      return;
    }

    final evaluationContext = EvaluationContext(
        () => feature.properties, feature.type, logger,
        zoom: context.zoom,
        zoomScaleFactor: context.zoomScaleFactor,
        hasImage: context.hasImage);
    final fillPaint = style.fillPaint?.evaluate(evaluationContext)?.paint();
    final outlinePaint =
        style.outlinePaint?.evaluate(evaluationContext)?.paint();

    if (outlinePaint != null) {
      final polygons = feature.paths;
      for (final polygon in polygons) {
        if (!context.optimizations.skipInBoundsChecks &&
            !context.tileSpaceMapper.isPathWithinTileClip(polygon)) {
          continue;
        }
        if (fillPaint != null) {
          context.canvas.drawPath(polygon.path, fillPaint);
        }

        context.canvas.drawPath(polygon.path, outlinePaint);
      }
      return;
    }

    if (fillPaint == null) {
      return;
    }

    const drawVertices = true;
    if (drawVertices) {
      // Flush previous.
      if (prevPaint != null && prevPaint != fillPaint) {
        context.canvas.drawVertices(
            toVerticesDouble(batchedTriangles), ui.BlendMode.src, prevPaint!);

        //print(batchSize);
        batchSize = 0;
        batchedTriangles.clear();
        prevPaint = null;
      }

      batchSize++;
      prevPaint = fillPaint;
      final triangles = batchedTriangles;

      final clip = context.tileSpaceMapper.tileClipInTileUnits;
      feature.pushTrianglePointsDouble(clip, triangles);

      // final vertices = feature.getVertices(clip);
      // context.canvas.drawVertices(vertices, ui.BlendMode.src, fillPaint);
    } else {
      final batchedPath = ui.Path();

      final polygons = feature.paths;
      for (final polygon in polygons) {
        if (!context.tileSpaceMapper.isPathWithinTileClip(polygon)) {
          continue;
        }
        batchedPath.addPath(polygon.path, const ui.Offset(0, 0));

        context.canvas.drawPath(batchedPath, fillPaint);
      }
    }

    if (forceFlush && prevPaint != null) {
      context.canvas.drawVertices(
          toVerticesDouble(batchedTriangles), ui.BlendMode.src, prevPaint!);

      batchedTriangles.clear();
      prevPaint = null;
      batchSize = 0;
    }
  }
}
