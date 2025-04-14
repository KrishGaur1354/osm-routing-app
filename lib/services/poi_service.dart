import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../models/poi.dart';

class POIService {
  // Singleton pattern
  static final POIService _instance = POIService._internal();
  factory POIService() => _instance;
  POIService._internal();
  
  // POI cache
  final List<POI> _cachedPOIs = [];
  final StreamController<List<POI>> _poisController = StreamController<List<POI>>.broadcast();
  
  // Getters
  Stream<List<POI>> get poisStream => _poisController.stream;
  List<POI> get pois => List.unmodifiable(_cachedPOIs);
  
  // Initialize with some mock data
  Future<void> initialize() async {
    _loadMockData();
    _poisController.add(_cachedPOIs);
  }
  
  // Search POIs by name or description
  List<POI> searchByText(String query) {
    if (query.isEmpty) return _cachedPOIs;
    
    final searchTerms = query.toLowerCase().split(' ');
    
    return _cachedPOIs.where((poi) {
      final name = poi.name.toLowerCase();
      final description = poi.description?.toLowerCase() ?? '';
      final address = poi.address?.toLowerCase() ?? '';
      
      return searchTerms.any((term) => 
        name.contains(term) || 
        description.contains(term) || 
        address.contains(term));
    }).toList();
  }
  
  // Filter POIs by category
  List<POI> filterByCategory(List<POICategory> categories) {
    if (categories.isEmpty) return _cachedPOIs;
    
    return _cachedPOIs.where((poi) => 
      categories.contains(poi.category)).toList();
  }
  
  // Find POIs around a location
  List<POI> findNearby(LatLng center, double radiusKm) {
    final distance = Distance();
    
    return _cachedPOIs.where((poi) {
      final distanceInKm = distance.as(
        LengthUnit.Kilometer, 
        center, 
        poi.position
      );
      return distanceInKm <= radiusKm;
    }).toList();
  }
  
  // Combined search with multiple filters
  List<POI> advancedSearch({
    String? textQuery,
    List<POICategory>? categories,
    LatLng? center,
    double? radiusKm,
    double? minRating,
  }) {
    List<POI> results = _cachedPOIs;
    
    // Apply text search
    if (textQuery != null && textQuery.isNotEmpty) {
      results = searchByText(textQuery);
    }
    
    // Apply category filter
    if (categories != null && categories.isNotEmpty) {
      results = results.where((poi) => 
        categories.contains(poi.category)).toList();
    }
    
    // Apply location filter
    if (center != null && radiusKm != null) {
      final distance = Distance();
      results = results.where((poi) {
        final distanceInKm = distance.as(
          LengthUnit.Kilometer, 
          center, 
          poi.position
        );
        return distanceInKm <= radiusKm;
      }).toList();
    }
    
    // Apply rating filter
    if (minRating != null) {
      results = results.where((poi) => 
        poi.rating != null && poi.rating! >= minRating).toList();
    }
    
    return results;
  }
  
  // Fetch POIs from OSM Overpass API
  Future<List<POI>> fetchFromOverpass(LatLng center, double radiusKm) async {
    try {
      final radius = radiusKm * 1000; // Convert to meters
      final query = """
        [out:json];
        (
          node["amenity"](around:$radius,${center.latitude},${center.longitude});
          node["tourism"](around:$radius,${center.latitude},${center.longitude});
          node["shop"](around:$radius,${center.latitude},${center.longitude});
        );
        out body;
      """;
      
      final response = await http.post(
        Uri.parse('https://overpass-api.de/api/interpreter'),
        body: query,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final elements = data['elements'] as List;
        
        final List<POI> results = [];
        
        for (var element in elements) {
          final tags = element['tags'] as Map<String, dynamic>?;
          if (tags == null || !tags.containsKey('name')) continue;
          
          final category = _determineCategoryFromTags(tags);
          final poi = POI(
            id: element['id'].toString(),
            name: tags['name'],
            position: LatLng(element['lat'], element['lon']),
            category: category,
            address: tags['addr:street'] != null && tags['addr:housenumber'] != null 
              ? '${tags['addr:street']} ${tags['addr:housenumber']}' 
              : null,
            description: tags['description'],
            additionalInfo: tags,
          );
          
          results.add(poi);
        }
        
        // Update cache with new results
        _updateCache(results);
        
        return results;
      }
      
      return [];
    } catch (e) {
      print('Error fetching POIs: $e');
      return [];
    }
  }
  
  // Helper to determine POI category from OSM tags
  POICategory _determineCategoryFromTags(Map<String, dynamic> tags) {
    if (tags.containsKey('amenity')) {
      final amenity = tags['amenity'];
      if (amenity == 'restaurant' || amenity == 'fast_food') return POICategory.restaurant;
      if (amenity == 'cafe') return POICategory.cafe;
      if (amenity == 'parking') return POICategory.parking;
      if (amenity == 'hospital') return POICategory.hospital;
      if (amenity == 'pharmacy') return POICategory.pharmacy;
      if (amenity == 'bank') return POICategory.bank;
      if (amenity == 'fuel') return POICategory.gas;
    }
    
    if (tags.containsKey('tourism')) {
      final tourism = tags['tourism'];
      if (tourism == 'hotel') return POICategory.hotel;
      if (tourism == 'attraction') return POICategory.attraction;
    }
    
    if (tags.containsKey('shop')) {
      return POICategory.shopping;
    }
    
    return POICategory.other;
  }
  
  // Add user-created POI
  Future<POI> addUserPOI(String name, LatLng position, POICategory category, {
    String? description, String? address
  }) async {
    final uuid = const Uuid().v4();
    final poi = POI(
      id: uuid,
      name: name,
      position: position,
      category: category,
      description: description,
      address: address,
      additionalInfo: {'isUserCreated': true},
    );
    
    _cachedPOIs.add(poi);
    _poisController.add(_cachedPOIs);
    
    return poi;
  }
  
  // Update cache with new POIs
  void _updateCache(List<POI> newPois) {
    // Remove POIs that overlap with new ones
    final newIds = newPois.map((p) => p.id).toSet();
    _cachedPOIs.removeWhere((p) => newIds.contains(p.id));
    
    // Add new POIs
    _cachedPOIs.addAll(newPois);
    
    // Notify listeners
    _poisController.add(_cachedPOIs);
  }
  
  // Load initial mock data for testing
  void _loadMockData() {
    final mockPOIs = [
      POI(
        id: '1',
        name: 'Central Park Restaurant',
        position: const LatLng(37.7749, -122.4194),
        category: POICategory.restaurant,
        address: '123 Park Ave',
        description: 'A lovely restaurant with park views',
        rating: 4.5,
      ),
      POI(
        id: '2',
        name: 'Grand Hotel',
        position: const LatLng(37.7790, -122.4180),
        category: POICategory.hotel,
        address: '500 Grand Blvd',
        description: 'Luxury accommodations in the heart of the city',
        rating: 4.8,
      ),
      POI(
        id: '3',
        name: 'City Museum',
        position: const LatLng(37.7710, -122.4120),
        category: POICategory.attraction,
        address: '200 History Lane',
        description: 'Explore the rich history of the city',
        rating: 4.6,
      ),
      POI(
        id: '4',
        name: 'Downtown Cafe',
        position: const LatLng(37.7730, -122.4170),
        category: POICategory.cafe,
        address: '350 Main St',
        description: 'Cozy cafe with artisanal coffee',
        rating: 4.2,
      ),
      POI(
        id: '5',
        name: 'Central Hospital',
        position: const LatLng(37.7780, -122.4140),
        category: POICategory.hospital,
        address: '1000 Health Drive',
        description: 'Full-service medical center',
        rating: 4.3,
      ),
    ];
    
    _cachedPOIs.addAll(mockPOIs);
  }
  
  // Dispose resources
  void dispose() {
    _poisController.close();
  }
} 