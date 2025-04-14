import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/heatmap_service.dart';

class HeatmapLayerWidget extends StatelessWidget {
  final HeatmapLayer layer;
  
  const HeatmapLayerWidget({
    Key? key,
    required this.layer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!layer.isVisible || layer.points.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return CustomLayerWidget(
      painter: HeatmapPainter(
        points: layer.points,
        startColor: layer.startColor,
        endColor: layer.endColor,
        radius: layer.radius,
      ),
    );
  }
}

class HeatmapPainter extends CustomPainter {
  final List<HeatPoint> points;
  final Color startColor;
  final Color endColor;
  final double radius;
  
  HeatmapPainter({
    required this.points,
    required this.startColor,
    required this.endColor,
    required this.radius,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    
    for (final point in points) {
      // Create a radial gradient for each point
      final shader = RadialGradient(
        colors: [
          _getIntensityColor(point.intensity),
          _getIntensityColor(0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(
        Rect.fromCircle(
          center: Offset.zero,
          radius: radius,
        ),
      );
      
      // Create a paint object with the gradient
      final paint = Paint()
        ..shader = shader
        ..style = PaintingStyle.fill
        ..strokeWidth = 1.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      
      // Draw the circle
      canvas.drawCircle(
        Offset.zero,
        radius,
        paint,
      );
    }
  }
  
  // Calculate the color based on intensity
  Color _getIntensityColor(double intensity) {
    return Color.lerp(
      startColor.withOpacity(0.0),
      endColor.withOpacity(0.7),
      intensity,
    )!;
  }
  
  @override
  bool shouldRepaint(covariant HeatmapPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.startColor != startColor ||
        oldDelegate.endColor != endColor ||
        oldDelegate.radius != radius;
  }
}

class CustomLayerWidget extends StatefulWidget {
  final CustomPainter painter;
  
  const CustomLayerWidget({
    Key? key,
    required this.painter,
  }) : super(key: key);

  @override
  State<CustomLayerWidget> createState() => _CustomLayerWidgetState();
}

class _CustomLayerWidgetState extends State<CustomLayerWidget> {
  @override
  Widget build(BuildContext context) {
    final map = MapCamera.of(context);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: constraints.biggest,
          painter: _MapCustomPainter(
            mapCamera: map,
            painter: widget.painter,
          ),
        );
      },
    );
  }
}

class _MapCustomPainter extends CustomPainter {
  final MapCamera mapCamera;
  final CustomPainter painter;
  
  _MapCustomPainter({
    required this.mapCamera,
    required this.painter,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // For each point in the heatmap, calculate its position on the screen
    final points = <Offset>[];
    final intensities = <double>[];
    
    // Check if the painter is a HeatmapPainter
    if (painter is HeatmapPainter) {
      final heatmapPainter = painter as HeatmapPainter;
      
      for (final point in heatmapPainter.points) {
        // Convert LatLng to pixel coordinates
        final pixelPos = mapCamera.project(point.position);
        
        // Convert to local coordinates
        final localPos = pixelPos - mapCamera.pixelOrigin;
        
        points.add(Offset(localPos.x.toDouble(), localPos.y.toDouble()));
        intensities.add(point.intensity);
      }
      
      // Draw each point
      for (int i = 0; i < points.length; i++) {
        // Save the canvas state
        canvas.save();
        
        // Translate to the point's position
        canvas.translate(points[i].dx, points[i].dy);
        
        // Create a local gradient
        final shader = RadialGradient(
          colors: [
            _getIntensityColor(intensities[i], heatmapPainter.startColor, heatmapPainter.endColor),
            _getIntensityColor(0, heatmapPainter.startColor, heatmapPainter.endColor),
          ],
          stops: const [0.0, 1.0],
        ).createShader(
          Rect.fromCircle(
            center: Offset.zero,
            radius: heatmapPainter.radius,
          ),
        );
        
        // Draw the circle
        final paint = Paint()
          ..shader = shader
          ..style = PaintingStyle.fill
          ..strokeWidth = 1.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
        
        canvas.drawCircle(
          Offset.zero,
          heatmapPainter.radius,
          paint,
        );
        
        // Restore the canvas state
        canvas.restore();
      }
    }
  }
  
  // Calculate the color based on intensity
  Color _getIntensityColor(double intensity, Color startColor, Color endColor) {
    return Color.lerp(
      startColor.withOpacity(0.0),
      endColor.withOpacity(0.7),
      intensity,
    )!;
  }
  
  @override
  bool shouldRepaint(covariant _MapCustomPainter oldDelegate) {
    return oldDelegate.mapCamera != mapCamera ||
        oldDelegate.painter != painter;
  }
} 