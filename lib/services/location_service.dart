import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  // Singleton pattern
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final StreamController<Position> _locationController = StreamController<Position>.broadcast();
  StreamSubscription<Position>? _positionStreamSubscription;

  Stream<Position> get locationStream => _locationController.stream;

  // Request location permissions
  Future<bool> requestLocationPermission() async {
    // Skip permission request on web and desktop platforms
    if (kIsWeb || !(defaultTargetPlatform == TargetPlatform.android || 
                   defaultTargetPlatform == TargetPlatform.iOS)) {
      return true;
    }
    
    try {
      var status = await Permission.locationWhenInUse.status;
      if (status.isDenied) {
        status = await Permission.locationWhenInUse.request();
      }
      
      // For background location (optional)
      if (status.isGranted) {
        var backgroundStatus = await Permission.locationAlways.status;
        if (backgroundStatus.isDenied) {
          backgroundStatus = await Permission.locationAlways.request();
        }
      }
      
      return status.isGranted;
    } catch (e) {
      print('Error requesting location permission: $e');
      return false;
    }
  }

  // Get current position
  Future<Position?> getCurrentPosition() async {
    bool hasPermission = await requestLocationPermission();
    if (!hasPermission) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting current position: $e');
      return null;
    }
  }

  // Start listening to location updates
  Future<void> startLocationUpdates() async {
    bool hasPermission = await requestLocationPermission();
    if (!hasPermission) {
      return;
    }

    // Cancel any existing subscription
    await _positionStreamSubscription?.cancel();

    // Start a new subscription
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((Position position) {
      _locationController.add(position);
    }, onError: (error) {
      print('Location stream error: $error');
    });
  }

  // Stop listening to location updates
  Future<void> stopLocationUpdates() async {
    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  // Dispose resources
  void dispose() {
    stopLocationUpdates();
    _locationController.close();
  }
} 