import 'package:flutter/material.dart';

class MapControlPanel extends StatelessWidget {
  final Function() onZoomIn;
  final Function() onZoomOut;
  final Function() onMyLocation;
  final Function() onEditToggle;
  final bool isEditMode;
  
  const MapControlPanel({
    Key? key,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onMyLocation,
    required this.onEditToggle,
    required this.isEditMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Zoom in button
            _buildControlButton(
              icon: Icons.add,
              tooltip: 'Zoom in',
              onPressed: onZoomIn,
            ),
            const Divider(height: 1),
            
            // Zoom out button
            _buildControlButton(
              icon: Icons.remove,
              tooltip: 'Zoom out',
              onPressed: onZoomOut,
            ),
            const Divider(height: 1),
            
            // My location button
            _buildControlButton(
              icon: Icons.my_location,
              tooltip: 'My location',
              onPressed: onMyLocation,
            ),
            const Divider(height: 1),
            
            // Edit toggle button
            _buildControlButton(
              icon: isEditMode ? Icons.close : Icons.edit,
              tooltip: isEditMode ? 'Cancel editing' : 'Edit map',
              onPressed: onEditToggle,
              color: isEditMode ? Colors.red : null,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildControlButton({
    required IconData icon,
    required String tooltip,
    required Function() onPressed,
    Color? color,
  }) {
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
        icon: Icon(icon, color: color),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
} 