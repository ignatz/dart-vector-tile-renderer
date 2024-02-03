import 'dart:ui' as ui;

import '../../vector_tile_renderer.dart';
import '../context.dart';
import '../path/path_transform.dart';
import '../path/ring_number_provider.dart';
import '../themes/expression/expression.dart';
import '../themes/style.dart';
import 'extensions.dart';
import 'feature_renderer.dart';

class LineRenderer extends FeatureRenderer {
  final Logger logger;

  LineRenderer(this.logger);

  @override
  void render(
    Context context,
    ThemeLayerType layerType,
    Style style,
    TileLayer layer,
    TileFeature feature,
  ) {
    if (!feature.hasPaths) {
      return;
    }
    final linePaintExpression = style.linePaint;
    if (linePaintExpression == null) {
      logger.warn(() =>
          'line does not have a line paint for vector tile layer ${layer.name}');
      return;
    }

    final evaluationContext = EvaluationContext(
        () => feature.properties, feature.type, logger,
        zoom: context.zoom,
        zoomScaleFactor: context.zoomScaleFactor,
        hasImage: context.hasImage);

    final paint = style.linePaint?.evaluate(evaluationContext);
    if (paint == null) {
      return;
    }

    final effectivePaintProvider = context.paintProvider.provide(
      evaluationContext,
      paint: linePaintExpression,
      strokeWidthModifier: (strokeWidth) {
        if (context.zoomScaleFactor > 1.0) {
          strokeWidth = strokeWidth / context.zoomScaleFactor;
        }
        return strokeWidth;
      },
      widthModifier: (strokeWidth) =>
          context.tileSpaceMapper.widthFromPixelToTile(strokeWidth),
    );
    if (effectivePaintProvider == null) {
      return;
    }

    final effectivePaint = effectivePaintProvider.paint();
    final dashLengths = effectivePaintProvider.strokeDashPattern;
    final lines = feature.paths;

    const batch = true;
    if (batch) {
      final batchedPath = ui.Path();
      for (var line in lines) {
        if (!context.tileSpaceMapper.isPathWithinTileClip(line)) {
          continue;
        }

        var path = line.path;
        if (dashLengths != null) {
          path = path.dashPath(RingNumberProvider(dashLengths));
        }

        batchedPath.addPath(path, const ui.Offset(0, 0));
      }
      context.canvas.drawPath(batchedPath, effectivePaint);
    } else {
      for (var line in lines) {
        if (!context.tileSpaceMapper.isPathWithinTileClip(line)) {
          continue;
        }
        var path = line.path;
        if (dashLengths != null) {
          path = path.dashPath(RingNumberProvider(dashLengths));
        }
        context.canvas.drawPath(path, effectivePaint);
      }
    }
  }
}
