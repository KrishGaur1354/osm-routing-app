import 'package:latlong2/latlong.dart';

enum POICategory {
  restaurant,
  hotel,
  cafe,
  attraction,
  shopping,
  gas,
  parking,
  hospital,
  pharmacy,
  bank,
  other
}

class POI {
  final String id;
  final String name;
  final LatLng position;
  final POICategory category;
  final String? address;
  final String? description;
  final double? rating;
  final Map<String, dynamic>? additionalInfo;
  
  const POI({
    required this.id,
    required this.name,
    required this.position,
    required this.category,
    this.address,
    this.description,
    this.rating,
    this.additionalInfo,
  });
  
  // Static method to get icon for each category
  static String getCategoryIcon(POICategory category) {
    switch (category) {
      case POICategory.restaurant:
        return 'restaurant';
      case POICategory.hotel:
        return 'hotel';
      case POICategory.cafe:
        return 'local_cafe';
      case POICategory.attraction:
        return 'attractions';
      case POICategory.shopping:
        return 'shopping_bag';
      case POICategory.gas:
        return 'local_gas_station';
      case POICategory.parking:
        return 'local_parking';
      case POICategory.hospital:
        return 'local_hospital';
      case POICategory.pharmacy:
        return 'local_pharmacy';
      case POICategory.bank:
        return 'account_balance';
      case POICategory.other:
        return 'place';
    }
  }
  
  // Static method to get color for each category
  static int getCategoryColor(POICategory category) {
    switch (category) {
      case POICategory.restaurant:
        return 0xFFFF5722; // Deep Orange
      case POICategory.hotel:
        return 0xFF9C27B0; // Purple
      case POICategory.cafe:
        return 0xFF795548; // Brown
      case POICategory.attraction:
        return 0xFF4CAF50; // Green
      case POICategory.shopping:
        return 0xFFE91E63; // Pink
      case POICategory.gas:
        return 0xFFFF9800; // Orange
      case POICategory.parking:
        return 0xFF2196F3; // Blue
      case POICategory.hospital:
        return 0xFFF44336; // Red
      case POICategory.pharmacy:
        return 0xFF4CAF50; // Green
      case POICategory.bank:
        return 0xFF607D8B; // Blue Grey
      case POICategory.other:
        return 0xFF9E9E9E; // Grey
    }
  }
  
  // Create from json data (for API integration)
  factory POI.fromJson(Map<String, dynamic> json) {
    return POI(
      id: json['id'],
      name: json['name'],
      position: LatLng(json['lat'], json['lon']),
      category: _categoryFromString(json['category']),
      address: json['address'],
      description: json['description'],
      rating: json['rating']?.toDouble(),
      additionalInfo: json['additionalInfo'],
    );
  }
  
  // Convert to json for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'lat': position.latitude,
      'lon': position.longitude,
      'category': category.toString(),
      'address': address,
      'description': description,
      'rating': rating,
      'additionalInfo': additionalInfo,
    };
  }
  
  // Helper method to parse category from string
  static POICategory _categoryFromString(String? categoryStr) {
    if (categoryStr == null) return POICategory.other;
    
    try {
      return POICategory.values.firstWhere(
        (e) => e.toString().toLowerCase().contains(categoryStr.toLowerCase())
      );
    } catch (e) {
      return POICategory.other;
    }
  }
} 