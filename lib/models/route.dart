import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';

class RoutePoint {
  final LatLng position;
  final DateTime timestamp;
  final double? elevation;
  final double? speed;
  
  const RoutePoint({
    required this.position,
    required this.timestamp,
    this.elevation,
    this.speed,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'timestamp': timestamp.toIso8601String(),
      'elevation': elevation,
      'speed': speed,
    };
  }
  
  factory RoutePoint.fromJson(Map<String, dynamic> json) {
    return RoutePoint(
      position: LatLng(json['latitude'], json['longitude']),
      timestamp: DateTime.parse(json['timestamp']),
      elevation: json['elevation'],
      speed: json['speed'],
    );
  }
}

class RouteTrack {
  final String id;
  final String name;
  final DateTime startTime;
  DateTime? endTime;
  final List<RoutePoint> points;
  final Color color;
  final String? description;
  bool isFavorite;
  
  RouteTrack({
    required this.id,
    required this.name,
    required this.startTime,
    this.endTime,
    required this.points,
    this.color = Colors.blue,
    this.description,
    this.isFavorite = false,
  });
  
  // Calculate the total distance of the route in meters
  double get totalDistance {
    final distance = Distance();
    double total = 0;
    
    for (int i = 0; i < points.length - 1; i++) {
      total += distance.as(
        LengthUnit.Meter,
        points[i].position,
        points[i + 1].position,
      );
    }
    
    return total;
  }
  
  // Calculate the duration of the route
  Duration get duration {
    if (points.isEmpty) {
      return Duration.zero;
    }
    
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }
  
  // Calculate average speed in km/h
  double get averageSpeed {
    if (points.isEmpty || duration.inSeconds == 0) {
      return 0;
    }
    
    // Convert meters to kilometers and seconds to hours
    return (totalDistance / 1000) / (duration.inSeconds / 3600);
  }
  
  // Add a new point to the route
  void addPoint(RoutePoint point) {
    points.add(point);
  }
  
  // End the route tracking
  void endRoute() {
    endTime = DateTime.now();
  }
  
  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'points': points.map((p) => p.toJson()).toList(),
      'color': color.value,
      'description': description,
      'isFavorite': isFavorite,
    };
  }
  
  // Create from JSON
  factory RouteTrack.fromJson(Map<String, dynamic> json) {
    return RouteTrack(
      id: json['id'],
      name: json['name'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      points: (json['points'] as List)
          .map((p) => RoutePoint.fromJson(p))
          .toList(),
      color: Color(json['color']),
      description: json['description'],
      isFavorite: json['isFavorite'] ?? false,
    );
  }
} 