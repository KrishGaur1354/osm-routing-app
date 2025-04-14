import 'package:flutter/material.dart';
import '../models/map_marker.dart';

class CustomMarker extends StatelessWidget {
  final MarkerType markerType;
  final Color? color;
  
  const CustomMarker({
    Key? key,
    required this.markerType,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _buildMarkerIcon(context);
  }
  
  Widget _buildMarkerIcon(BuildContext context) {
    final defaultColor = Theme.of(context).primaryColor;
    final markerColor = color ?? _getColorForType(context);
    
    // User marker is special with an animated pulse effect
    if (markerType == MarkerType.user) {
      return Stack(
        children: [
          // Outer animated pulse
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(seconds: 2),
            curve: Curves.easeInOut, 
            builder: (context, value, child) {
              return Container(
                width: 50 + (value * 10),
                height: 50 + (value * 10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.3 * (1 - value)),
                  shape: BoxShape.circle,
                ),
              );
            },
            // Restart animation when completed
            onEnd: () => (context as Element).markNeedsBuild(),
          ),
          
          // Inner circle
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.blue,
                width: 3,
              ),
            ),
          ),
        ],
      );
    }
    
    // Regular markers (pin style)
    return Stack(
      children: [
        // Shadow
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        
        // Pin
        Icon(
          _getIconForType(),
          color: markerColor,
          size: 36,
          shadows: const [
            Shadow(
              color: Colors.black38,
              blurRadius: 5,
              offset: Offset(2, 2),
            ),
          ],
        ),
      ],
    );
  }
  
  IconData _getIconForType() {
    switch (markerType) {
      case MarkerType.user:
        return Icons.person_pin_circle;
      case MarkerType.point:
        return Icons.place;
      case MarkerType.restaurant:
        return Icons.restaurant;
      case MarkerType.hotel:
        return Icons.hotel;
      case MarkerType.attraction:
        return Icons.attractions;
      case MarkerType.custom:
        return Icons.star;
    }
  }
  
  Color _getColorForType(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    
    switch (markerType) {
      case MarkerType.user:
        return Colors.blue;
      case MarkerType.point:
        return primaryColor;
      case MarkerType.restaurant:
        return Colors.orange;
      case MarkerType.hotel:
        return Colors.purple;
      case MarkerType.attraction:
        return Colors.green;
      case MarkerType.custom:
        return Colors.amber;
    }
  }
} 