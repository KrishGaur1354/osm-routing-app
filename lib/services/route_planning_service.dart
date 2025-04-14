import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

enum TransportMode {
  walking,
  cycling,
  driving,
  transit
}

class RoutePoint {
  final LatLng position;
  final String? name;
  final String? instructions;
  final double? distance; // in meters
  final Duration? duration;
  
  RoutePoint({
    required this.position,
    this.name,
    this.instructions,
    this.distance,
    this.duration,
  });
}

class PlannedRoute {
  final String id;
  final List<RoutePoint> points;
  final TransportMode mode;
  final double totalDistance; // in meters
  final Duration totalDuration;
  final Color color;
  
  PlannedRoute({
    required this.id,
    required this.points,
    required this.mode,
    required this.totalDistance,
    required this.totalDuration,
    this.color = Colors.blue,
  });
  
  String get formattedDistance {
    if (totalDistance < 1000) {
      return '${totalDistance.toStringAsFixed(0)} m';
    } else {
      return '${(totalDistance / 1000).toStringAsFixed(1)} km';
    }
  }
  
  String get formattedDuration {
    final hours = totalDuration.inHours;
    final minutes = totalDuration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '$hours hr $minutes min';
    } else {
      return '$minutes min';
    }
  }
  
  IconData get modeIcon {
    switch (mode) {
      case TransportMode.walking:
        return Icons.directions_walk;
      case TransportMode.cycling:
        return Icons.directions_bike;
      case TransportMode.driving:
        return Icons.directions_car;
      case TransportMode.transit:
        return Icons.directions_bus;
    }
  }
}

class RouteAlternative {
  final PlannedRoute route;
  final String description;
  
  RouteAlternative({
    required this.route,
    required this.description,
  });
}

class RoutePlanningService {
  static final RoutePlanningService _instance = RoutePlanningService._internal();
  
  factory RoutePlanningService() {
    return _instance;
  }
  
  RoutePlanningService._internal();
  
  // Stream controller for planned routes
  final _routesController = StreamController<List<PlannedRoute>>.broadcast();
  Stream<List<PlannedRoute>> get routesStream => _routesController.stream;
  
  // List of planned routes
  final List<PlannedRoute> _plannedRoutes = [];
  
  // The currently active route
  PlannedRoute? _activeRoute;
  
  // OpenRouteService API key - you need to get your own key from https://openrouteservice.org/
  // This is a placeholder - replace with your actual API key
  final String _apiKey = 'YOUR_OPENROUTESERVICE_API_KEY';
  
  // Base URL for OpenRouteService API
  final String _baseUrl = 'https://api.openrouteservice.org/v2/directions';
  
  // Initialize the service
  Future<void> initialize() async {
    // If needed, load saved routes from local storage
    
    // Notify listeners with initial data
    _routesController.add(_plannedRoutes);
  }
  
  // Get profile string for ORS API based on transport mode
  String _getProfile(TransportMode mode) {
    switch (mode) {
      case TransportMode.walking:
        return 'foot-walking';
      case TransportMode.cycling:
        return 'cycling-regular';
      case TransportMode.driving:
        return 'driving-car';
      case TransportMode.transit:
        return 'public-transport'; // Might not be supported by ORS
    }
  }
  
  // Plan a route between two points using OpenRouteService
  Future<List<RouteAlternative>> planRoute(
    LatLng start, 
    LatLng end, 
    TransportMode mode,
    {List<LatLng>? waypoints}
  ) async {
    try {
      // Build coordinates array
      final coordinates = [
        [start.longitude, start.latitude]
      ];
      
      // Add waypoints if any
      if (waypoints != null) {
        for (var point in waypoints) {
          coordinates.add([point.longitude, point.latitude]);
        }
      }
      
      // Add destination
      coordinates.add([end.longitude, end.latitude]);
      
      // Build request URL
      final profile = _getProfile(mode);
      final url = '$_baseUrl/$profile';
      
      // Make API request
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': _apiKey,
        },
        body: jsonEncode({
          'coordinates': coordinates,
          'instructions': true,
          'preference': 'recommended',
          'format': 'geojson',
          'units': 'metric',
          'language': 'en',
          'geometry_simplify': true,
        }),
      );
      
      // Check for successful response
      if (response.statusCode == 200) {
        // Parse the response
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        // For demonstration purposes, fall back to mock data if API key is not set
        if (_apiKey == 'YOUR_OPENROUTESERVICE_API_KEY') {
          return _generateMockRouteAlternatives(start, end, mode);
        }
        
        // Extract routes from the response
        final List<RouteAlternative> alternatives = [];
        
        if (data.containsKey('features')) {
          final features = data['features'] as List;
          
          for (var i = 0; i < features.length; i++) {
            final feature = features[i];
            final properties = feature['properties'];
            final geometry = feature['geometry'];
            
            // Extract summary
            final summary = properties['summary'];
            final totalDistance = (summary['distance'] as num).toDouble();
            final totalDuration = Duration(seconds: (summary['duration'] as num).round());
            
            // Extract route points
            final coordinates = geometry['coordinates'] as List;
            List<RoutePoint> points = [];
            
            for (var j = 0; j < coordinates.length; j++) {
              final coord = coordinates[j];
              points.add(RoutePoint(
                position: LatLng(coord[1], coord[0]),
              ));
            }
            
            // Extract step instructions if available
            if (properties.containsKey('segments')) {
              final segments = properties['segments'] as List;
              
              for (var segment in segments) {
                if (segment.containsKey('steps')) {
                  final steps = segment['steps'] as List;
                  int pointIndex = 0;
                  
                  for (var step in steps) {
                    final instruction = step['instruction'] as String;
                    final stepDistance = (step['distance'] as num).toDouble();
                    final stepDuration = Duration(seconds: (step['duration'] as num).round());
                    
                    // Update the corresponding point with instruction
                    if (pointIndex < points.length) {
                      points[pointIndex] = RoutePoint(
                        position: points[pointIndex].position,
                        instructions: instruction,
                        distance: stepDistance,
                        duration: stepDuration,
                      );
                    }
                    
                    pointIndex++;
                  }
                }
              }
            }
            
            // Create the planned route
            final route = PlannedRoute(
              id: 'route_${DateTime.now().millisecondsSinceEpoch}_$i',
              points: points,
              mode: mode,
              totalDistance: totalDistance,
              totalDuration: totalDuration,
              color: _getRouteColor(mode),
            );
            
            // Add to alternatives
            alternatives.add(RouteAlternative(
              route: route,
              description: i == 0 ? 'Recommended route' : 'Alternative ${i}',
            ));
          }
        }
        
        return alternatives;
      } else {
        print('Failed to load route: ${response.statusCode}');
        return _generateMockRouteAlternatives(start, end, mode);
      }
    } catch (e) {
      print('Error planning route: $e');
      return _generateMockRouteAlternatives(start, end, mode);
    }
  }
  
  // Generate mock route for testing purposes
  List<RouteAlternative> _generateMockRouteAlternatives(
    LatLng start, 
    LatLng end, 
    TransportMode mode
  ) {
    List<RouteAlternative> alternatives = [];
    
    // Create different route variations
    final routes = [
      _generateMockRoute(start, end, mode, 1.0),
      _generateMockRoute(start, end, mode, 1.1),
      _generateMockRoute(start, end, mode, 1.2),
    ];
    
    // Add descriptions
    alternatives.add(RouteAlternative(
      route: routes[0],
      description: 'Fastest route',
    ));
    
    alternatives.add(RouteAlternative(
      route: routes[1],
      description: 'Shorter distance',
    ));
    
    alternatives.add(RouteAlternative(
      route: routes[2],
      description: 'Less traffic',
    ));
    
    return alternatives;
  }
  
  // Generate a mock route between points
  PlannedRoute _generateMockRoute(
    LatLng start, 
    LatLng end, 
    TransportMode mode, 
    double variation
  ) {
    // Calculate direct distance
    final distance = const Distance().distance(start, end);
    
    // Generate route points with slight variation
    final numPoints = (distance / 300).round().clamp(5, 20);
    final points = <RoutePoint>[];
    
    for (var i = 0; i < numPoints; i++) {
      final fraction = i / (numPoints - 1);
      
      // Linear interpolation with some random variation
      final lat = start.latitude + (end.latitude - start.latitude) * fraction;
      final lng = start.longitude + (end.longitude - start.longitude) * fraction;
      
      // Add slight variation to make it look like a real route
      final latVariation = (hashCode % 100) / 10000 * variation;
      final lngVariation = (i * 3 % 100) / 10000 * variation;
      
      points.add(RoutePoint(
        position: LatLng(lat + latVariation, lng + lngVariation),
        instructions: i == 0 ? 'Start' : i == numPoints - 1 ? 'Arrive at destination' : null,
      ));
    }
    
    // Calculate simulated duration based on transport mode and distance
    double speedMps; // meters per second
    switch (mode) {
      case TransportMode.walking:
        speedMps = 1.4; // ~5 km/h
        break;
      case TransportMode.cycling:
        speedMps = 4.0; // ~15 km/h
        break;
      case TransportMode.driving:
        speedMps = 11.0; // ~40 km/h in city
        break;
      case TransportMode.transit:
        speedMps = 8.0; // ~30 km/h average including stops
        break;
    }
    
    final totalDistance = distance * variation;
    final durationSeconds = totalDistance / speedMps;
    
    return PlannedRoute(
      id: 'mock_route_${DateTime.now().millisecondsSinceEpoch}',
      points: points,
      mode: mode,
      totalDistance: totalDistance,
      totalDuration: Duration(seconds: durationSeconds.round()),
      color: _getRouteColor(mode),
    );
  }
  
  // Get color for the route based on transport mode
  Color _getRouteColor(TransportMode mode) {
    switch (mode) {
      case TransportMode.walking:
        return Colors.green;
      case TransportMode.cycling:
        return Colors.orange;
      case TransportMode.driving:
        return Colors.blue;
      case TransportMode.transit:
        return Colors.purple;
    }
  }
  
  // Save a planned route
  void saveRoute(PlannedRoute route) {
    _plannedRoutes.add(route);
    _routesController.add(_plannedRoutes);
    // TODO: Save to local storage
  }
  
  // Set the active route
  void setActiveRoute(PlannedRoute route) {
    _activeRoute = route;
    // Notify listeners that a new route is active
    _routesController.add(_plannedRoutes);
  }
  
  // Clear the active route
  void clearActiveRoute() {
    _activeRoute = null;
    _routesController.add(_plannedRoutes);
  }
  
  // Dispose resources
  void dispose() {
    _routesController.close();
  }
} 