import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class HeatPoint {
  final LatLng position;
  final double intensity; // 0.0 to 1.0
  final String? label;
  
  HeatPoint({
    required this.position,
    required this.intensity,
    this.label,
  });
}

class HeatmapLayer {
  final String id;
  final String name;
  final String description;
  final List<HeatPoint> points;
  final Color startColor;
  final Color endColor;
  final double radius;
  final bool isVisible;
  
  HeatmapLayer({
    required this.id,
    required this.name,
    required this.description,
    required this.points,
    this.startColor = const Color(0xFF00FF00), // Green
    this.endColor = const Color(0xFFFF0000),   // Red
    this.radius = 25.0,
    this.isVisible = true,
  });
  
  HeatmapLayer copyWith({
    String? id,
    String? name,
    String? description,
    List<HeatPoint>? points,
    Color? startColor,
    Color? endColor,
    double? radius,
    bool? isVisible,
  }) {
    return HeatmapLayer(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      points: points ?? this.points,
      startColor: startColor ?? this.startColor,
      endColor: endColor ?? this.endColor,
      radius: radius ?? this.radius,
      isVisible: isVisible ?? this.isVisible,
    );
  }
}

class HeatmapService {
  static final HeatmapService _instance = HeatmapService._internal();
  
  factory HeatmapService() {
    return _instance;
  }
  
  HeatmapService._internal();
  
  // Stream controller for heatmap layers
  final _layersController = StreamController<List<HeatmapLayer>>.broadcast();
  Stream<List<HeatmapLayer>> get layersStream => _layersController.stream;
  
  // List of heatmap layers
  final List<HeatmapLayer> _layers = [];
  
  // Currently selected layer
  String? _selectedLayerId;
  
  // Initialize the service with sample data
  Future<void> initialize() async {
    // Create sample heatmap layers
    _createSampleData();
    
    // Notify listeners
    _layersController.add(_layers);
  }
  
  // Create a new heatmap layer
  void createLayer({
    required String name,
    required String description,
    required List<HeatPoint> points,
    Color startColor = const Color(0xFF00FF00),
    Color endColor = const Color(0xFFFF0000),
    double radius = 25.0,
  }) {
    final id = 'layer_${DateTime.now().millisecondsSinceEpoch}';
    
    final layer = HeatmapLayer(
      id: id,
      name: name,
      description: description,
      points: points,
      startColor: startColor,
      endColor: endColor,
      radius: radius,
    );
    
    _layers.add(layer);
    _layersController.add(_layers);
  }
  
  // Update an existing layer
  void updateLayer(HeatmapLayer updatedLayer) {
    final index = _layers.indexWhere((layer) => layer.id == updatedLayer.id);
    
    if (index != -1) {
      _layers[index] = updatedLayer;
      _layersController.add(_layers);
    }
  }
  
  // Delete a layer
  void deleteLayer(String layerId) {
    _layers.removeWhere((layer) => layer.id == layerId);
    
    if (_selectedLayerId == layerId) {
      _selectedLayerId = _layers.isNotEmpty ? _layers.first.id : null;
    }
    
    _layersController.add(_layers);
  }
  
  // Toggle layer visibility
  void toggleLayerVisibility(String layerId) {
    final index = _layers.indexWhere((layer) => layer.id == layerId);
    
    if (index != -1) {
      final layer = _layers[index];
      _layers[index] = layer.copyWith(isVisible: !layer.isVisible);
      _layersController.add(_layers);
    }
  }
  
  // Set selected layer
  void setSelectedLayer(String? layerId) {
    _selectedLayerId = layerId;
    _layersController.add(_layers);
  }
  
  // Get the currently selected layer
  HeatmapLayer? getSelectedLayer() {
    if (_selectedLayerId == null) return null;
    
    try {
      return _layers.firstWhere(
        (layer) => layer.id == _selectedLayerId,
      );
    } catch (e) {
      return _layers.isNotEmpty ? _layers.first : null;
    }
  }
  
  // Create sample heatmap data
  void _createSampleData() {
    // Sample 1: Traffic hotspots
    _createTrafficHeatmap();
    
    // Sample 2: Popular areas
    _createPopularityHeatmap();
    
    // Sample 3: Environmental data
    _createEnvironmentalHeatmap();
  }
  
  // Create traffic heatmap
  void _createTrafficHeatmap() {
    final Random random = Random(42); // Fixed seed for reproducible results
    
    // Define center point (assuming San Francisco)
    final LatLng center = const LatLng(37.7749, -122.4194);
    
    // Generate points with higher density in city center
    final List<HeatPoint> points = [];
    
    // Create high traffic areas along main roads
    for (int i = 0; i < 200; i++) {
      // Create a road-like pattern
      double distance = random.nextDouble() * 0.05;
      double angle = random.nextDouble() * 2 * pi;
      
      // Add randomness to make it look more natural
      if (i % 5 == 0) {
        angle = pi / 2; // North-South road
      } else if (i % 7 == 0) {
        angle = 0; // East-West road
      }
      
      final lat = center.latitude + distance * cos(angle);
      final lng = center.longitude + distance * sin(angle);
      
      // Higher intensity near the center
      final intensity = 1.0 - (distance / 0.05) + random.nextDouble() * 0.3;
      
      points.add(HeatPoint(
        position: LatLng(lat, lng),
        intensity: intensity.clamp(0.0, 1.0),
      ));
    }
    
    createLayer(
      name: 'Traffic Congestion',
      description: 'Shows areas with high traffic congestion',
      points: points,
      startColor: Colors.green,
      endColor: Colors.red,
      radius: 30.0,
    );
  }
  
  // Create popularity heatmap
  void _createPopularityHeatmap() {
    final Random random = Random(24);
    
    // Define center point
    final LatLng center = const LatLng(37.7749, -122.4194);
    
    // Define popular areas
    final List<LatLng> popularSpots = [
      const LatLng(37.8087, -122.4098), // Fisherman's Wharf
      const LatLng(37.7952, -122.3972), // Pier 39
      const LatLng(37.7785, -122.5155), // Golden Gate Park
      const LatLng(37.7596, -122.4269), // Mission District
      const LatLng(37.7924, -122.4102), // Chinatown
      const LatLng(37.8020, -122.4060), // Lombard Street
    ];
    
    // Generate points clustered around popular spots
    final List<HeatPoint> points = [];
    
    for (var spot in popularSpots) {
      // Create a cluster around each popular spot
      final int pointCount = 50 + random.nextInt(100); // 50-150 points per spot
      
      for (int i = 0; i < pointCount; i++) {
        // Randomize position around the spot
        final double radius = random.nextDouble() * 0.01; // About 1km
        final double angle = random.nextDouble() * 2 * pi;
        
        final lat = spot.latitude + radius * cos(angle);
        final lng = spot.longitude + radius * sin(angle);
        
        // Intensity decreases with distance from center
        final double intensity = 1.0 - (radius / 0.01) + random.nextDouble() * 0.2;
        
        points.add(HeatPoint(
          position: LatLng(lat, lng),
          intensity: intensity.clamp(0.0, 1.0),
        ));
      }
    }
    
    createLayer(
      name: 'Popular Areas',
      description: 'Shows areas with high visitor traffic',
      points: points,
      startColor: Colors.blue.shade300,
      endColor: Colors.purple,
      radius: 20.0,
    );
  }
  
  // Create environmental heatmap
  void _createEnvironmentalHeatmap() {
    final Random random = Random(36);
    
    // Define center point
    final LatLng center = const LatLng(37.7749, -122.4194);
    
    // Generate points for air quality (more sparse)
    final List<HeatPoint> points = [];
    
    // Create a grid of points
    for (double lat = center.latitude - 0.05; lat <= center.latitude + 0.05; lat += 0.005) {
      for (double lng = center.longitude - 0.05; lng <= center.longitude + 0.05; lng += 0.005) {
        // Create a wave pattern for air quality
        final double distanceFromCenter = sqrt(
          pow(lat - center.latitude, 2) + pow(lng - center.longitude, 2)
        );
        
        // Create a pattern with some randomness
        final double baseIntensity = sin(distanceFromCenter * 100) * 0.5 + 0.5;
        final double intensity = baseIntensity + random.nextDouble() * 0.2;
        
        points.add(HeatPoint(
          position: LatLng(lat, lng),
          intensity: intensity.clamp(0.0, 1.0),
        ));
      }
    }
    
    createLayer(
      name: 'Environmental Data',
      description: 'Air quality index visualization',
      points: points,
      startColor: Colors.blue,
      endColor: Colors.orange,
      radius: 40.0,
    );
  }
  
  // Dispose resources
  void dispose() {
    _layersController.close();
  }
} 