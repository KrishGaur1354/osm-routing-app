import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/route.dart';
import 'location_service.dart';
import 'distance_calculator_service.dart';

class RouteService {
  // Singleton pattern
  static final RouteService _instance = RouteService._internal();
  factory RouteService() => _instance;
  RouteService._internal();
  
  // Services
  final LocationService _locationService = LocationService();
  
  // Route tracking state
  RouteTrack? _currentRoute;
  final StreamController<RouteTrack?> _routeController = StreamController<RouteTrack?>.broadcast();
  StreamSubscription<Position>? _positionSubscription;
  
  // Saved routes
  List<RouteTrack> _savedRoutes = [];
  final StreamController<List<RouteTrack>> _savedRoutesController = StreamController<List<RouteTrack>>.broadcast();
  
  // Expose streams
  Stream<RouteTrack?> get currentRouteStream => _routeController.stream;
  Stream<List<RouteTrack>> get savedRoutesStream => _savedRoutesController.stream;
  
  // Getters
  RouteTrack? get currentRoute => _currentRoute;
  List<RouteTrack> get savedRoutes => List.unmodifiable(_savedRoutes);
  bool get isTracking => _currentRoute != null;
  
  // Initialize service
  Future<void> initialize() async {
    await _loadSavedRoutes();
    
    // If no saved routes, generate some dummy ones
    if (_savedRoutes.isEmpty) {
      await _generateDummyRoutes();
    }
  }
  
  // Generate dummy routes for demonstration
  Future<void> _generateDummyRoutes() async {
    final distanceCalculator = DistanceCalculatorService();
    final dummyRouteCoordinates = distanceCalculator.generateDummyRoutes();
    final routeNames = [
      'Morning Run to Rohini',
      'Weekend Trip to Connaught Place',
      'Evening Walk to India Gate',
      'Historical Tour to Red Fort'
    ];
    final routeDescriptions = [
      'Quick morning jog through local streets to Rohini',
      'Weekend exploration of central Delhi shopping district',
      'Beautiful evening stroll to the iconic India Gate',
      'Cultural exploration of the historic Red Fort'
    ];
    final routeColors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
    ];
    
    // Generate routes with different dates
    final now = DateTime.now();
    
    for (int i = 0; i < dummyRouteCoordinates.length; i++) {
      final coordinates = dummyRouteCoordinates[i];
      final routePoints = <RoutePoint>[];
      
      // Create route with points spaced 1 minute apart
      final startTime = now.subtract(Duration(days: i * 2 + 1));
      
      for (int j = 0; j < coordinates.length; j++) {
        final point = RoutePoint(
          position: coordinates[j],
          timestamp: startTime.add(Duration(minutes: j)),
          speed: 5.0 + (j * 0.2), // Gradually increasing speed
          elevation: 100 + (j * 5.0), // Gradually increasing elevation
        );
        routePoints.add(point);
      }
      
      // Create the route
      final route = RouteTrack(
        id: const Uuid().v4(),
        name: routeNames[i],
        startTime: startTime,
        endTime: startTime.add(Duration(minutes: coordinates.length - 1)),
        points: routePoints,
        color: routeColors[i],
        description: routeDescriptions[i],
        isFavorite: i == 0 || i == 2, // Make a couple favorites
      );
      
      _savedRoutes.add(route);
    }
    
    // Sort by date (newest first)
    _savedRoutes.sort((a, b) => b.startTime.compareTo(a.startTime));
    
    // Notify listeners
    _savedRoutesController.add(_savedRoutes);
    
    // Save to storage
    await _persistRoutes();
  }
  
  // Start tracking a new route
  Future<void> startRouteTracking(String routeName, {String? description, Color color = Colors.blue}) async {
    // If already tracking, stop current route first
    if (_currentRoute != null) {
      await stopRouteTracking();
    }
    
    // Request location permissions
    bool hasPermission = await _locationService.requestLocationPermission();
    if (!hasPermission) {
      return;
    }
    
    // Get current position
    Position? position = await _locationService.getCurrentPosition();
    if (position == null) {
      return;
    }
    
    // Create new route
    final routeId = const Uuid().v4();
    final initialPoint = RoutePoint(
      position: LatLng(position.latitude, position.longitude),
      timestamp: DateTime.now(),
      speed: position.speed,
    );
    
    _currentRoute = RouteTrack(
      id: routeId,
      name: routeName,
      startTime: DateTime.now(),
      points: [initialPoint],
      color: color,
      description: description,
    );
    
    // Start subscription to location updates
    _positionSubscription?.cancel();
    _positionSubscription = _locationService.locationStream.listen(_addPointToCurrentRoute);
    
    // Notify listeners
    _routeController.add(_currentRoute);
    
    // Start location updates
    _locationService.startLocationUpdates();
  }
  
  // Add a new point to the current route
  void _addPointToCurrentRoute(Position position) {
    if (_currentRoute == null) return;
    
    final point = RoutePoint(
      position: LatLng(position.latitude, position.longitude),
      timestamp: DateTime.now(),
      speed: position.speed,
      elevation: position.altitude,
    );
    
    _currentRoute!.addPoint(point);
    _routeController.add(_currentRoute);
  }
  
  // Stop tracking the current route
  Future<RouteTrack?> stopRouteTracking() async {
    if (_currentRoute == null) return null;
    
    // Cancel location subscription
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    
    // Complete the route
    _currentRoute!.endRoute();
    
    // Save the route
    final completedRoute = _currentRoute!;
    await _saveRoute(completedRoute);
    
    // Clear current route
    _currentRoute = null;
    _routeController.add(null);
    
    return completedRoute;
  }
  
  // Save a route to persistent storage
  Future<void> _saveRoute(RouteTrack route) async {
    // Add to saved routes
    _savedRoutes.add(route);
    _savedRoutesController.add(_savedRoutes);
    
    // Save to storage
    await _persistRoutes();
  }
  
  // Delete a saved route
  Future<void> deleteRoute(String routeId) async {
    _savedRoutes.removeWhere((route) => route.id == routeId);
    _savedRoutesController.add(_savedRoutes);
    
    // Update storage
    await _persistRoutes();
  }
  
  // Update a route's metadata
  Future<void> updateRoute(String routeId, {String? name, String? description, Color? color, bool? isFavorite}) async {
    final index = _savedRoutes.indexWhere((route) => route.id == routeId);
    if (index == -1) return;
    
    final route = _savedRoutes[index];
    
    final updatedRoute = RouteTrack(
      id: route.id,
      name: name ?? route.name,
      startTime: route.startTime,
      endTime: route.endTime,
      points: route.points,
      color: color ?? route.color,
      description: description ?? route.description,
      isFavorite: isFavorite ?? route.isFavorite,
    );
    
    _savedRoutes[index] = updatedRoute;
    _savedRoutesController.add(_savedRoutes);
    
    // Update storage
    await _persistRoutes();
  }
  
  // Load saved routes from storage
  Future<void> _loadSavedRoutes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final routesJson = prefs.getStringList('saved_routes');
      
      if (routesJson != null) {
        _savedRoutes = routesJson
            .map((json) => RouteTrack.fromJson(jsonDecode(json)))
            .toList();
        
        // Sort by date (newest first)
        _savedRoutes.sort((a, b) => b.startTime.compareTo(a.startTime));
        
        _savedRoutesController.add(_savedRoutes);
      }
    } catch (e) {
      print('Error loading routes: $e');
      _savedRoutes = [];
      _savedRoutesController.add(_savedRoutes);
    }
  }
  
  // Save routes to persistent storage
  Future<void> _persistRoutes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final routesJson = _savedRoutes
          .map((route) => jsonEncode(route.toJson()))
          .toList();
      
      await prefs.setStringList('saved_routes', routesJson);
    } catch (e) {
      print('Error saving routes: $e');
    }
  }
  
  // Dispose resources
  void dispose() {
    _positionSubscription?.cancel();
    _routeController.close();
    _savedRoutesController.close();
  }
} 