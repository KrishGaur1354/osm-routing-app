import 'dart:math';
import 'package:latlong2/latlong.dart';

class DistanceCalculatorService {
  // Singleton pattern
  static final DistanceCalculatorService _instance = DistanceCalculatorService._internal();
  factory DistanceCalculatorService() => _instance;
  DistanceCalculatorService._internal();

  // The distance calculator from latlong2 package
  final Distance _distance = const Distance();
  
  // Default location (Pitampura, Delhi)
  final LatLng delhiLocation = const LatLng(28.7041, 77.1025);

  // Calculate distance between two points in meters
  double calculateDistance(LatLng point1, LatLng point2) {
    return _distance.as(LengthUnit.Meter, point1, point2);
  }
  
  // Calculate distance between two points in kilometers
  double calculateDistanceInKm(LatLng point1, LatLng point2) {
    return _distance.as(LengthUnit.Kilometer, point1, point2);
  }
  
  // Estimate travel time based on distance and transport mode
  Duration estimateTravelTime(double distanceInMeters, TransportMode mode) {
    // Average speeds in meters per second
    final speedMap = {
      TransportMode.walking: 1.4, // 5 km/h
      TransportMode.cycling: 4.2, // 15 km/h
      TransportMode.driving: 11.1, // 40 km/h
      TransportMode.transit: 8.3, // 30 km/h
    };
    
    final speed = speedMap[mode] ?? speedMap[TransportMode.walking]!;
    final seconds = distanceInMeters / speed;
    
    return Duration(seconds: seconds.round());
  }
  
  // Format distance for display
  String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    } else {
      final km = distanceInMeters / 1000;
      return '${km.toStringAsFixed(1)} km';
    }
  }
  
  // Format duration for display
  String formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      final minutes = duration.inMinutes.remainder(60);
      return '${duration.inHours} h ${minutes > 0 ? '$minutes min' : ''}';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} min';
    } else {
      return '${duration.inSeconds} sec';
    }
  }
  
  // Calculate bearing between two points (for heading)
  double calculateBearing(LatLng start, LatLng end) {
    return _distance.bearing(start, end);
  }
  
  // Generate dummy routes near Delhi
  List<List<LatLng>> generateDummyRoutes() {
    // Create routes around Delhi
    final routes = <List<LatLng>>[];
    
    // Route 1: Pitampura to Rohini
    final route1 = [
      const LatLng(28.7041, 77.1025), // Pitampura
      const LatLng(28.7089, 77.1075),
      const LatLng(28.7129, 77.1154),
      const LatLng(28.7158, 77.1211),
      const LatLng(28.7195, 77.1243), // Rohini
    ];
    routes.add(route1);
    
    // Route 2: Pitampura to Connaught Place
    final route2 = [
      const LatLng(28.7041, 77.1025), // Pitampura
      const LatLng(28.6929, 77.1039),
      const LatLng(28.6814, 77.1097),
      const LatLng(28.6697, 77.1199),
      const LatLng(28.6562, 77.1289),
      const LatLng(28.6454, 77.1376),
      const LatLng(28.6331, 77.1487),
      const LatLng(28.6292, 77.2099), // Connaught Place
    ];
    routes.add(route2);
    
    // Route 3: Pitampura to India Gate
    final route3 = [
      const LatLng(28.7041, 77.1025), // Pitampura
      const LatLng(28.6929, 77.1139),
      const LatLng(28.6814, 77.1297),
      const LatLng(28.6697, 77.1399),
      const LatLng(28.6562, 77.1589),
      const LatLng(28.6454, 77.1776),
      const LatLng(28.6331, 77.1887),
      const LatLng(28.6129, 77.2310), // India Gate
    ];
    routes.add(route3);
    
    // Route 4: Pitampura to Red Fort
    final route4 = [
      const LatLng(28.7041, 77.1025), // Pitampura
      const LatLng(28.6989, 77.1239),
      const LatLng(28.6914, 77.1397),
      const LatLng(28.6797, 77.1499),
      const LatLng(28.6662, 77.1689),
      const LatLng(28.6554, 77.1876),
      const LatLng(28.6331, 77.2187),
      const LatLng(28.6562, 77.2410), // Red Fort
    ];
    routes.add(route4);
    
    return routes;
  }
}

enum TransportMode {
  walking,
  cycling,
  driving,
  transit
} 