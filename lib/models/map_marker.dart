import 'package:latlong2/latlong.dart';

enum MarkerType {
  user,
  point,
  restaurant,
  hotel,
  attraction,
  custom
}

class MapMarker {
  final String id;
  final LatLng position;
  final String? title;
  final String? description;
  final MarkerType type;
  final Map<String, dynamic>? extraData;
  
  const MapMarker({
    required this.id,
    required this.position,
    this.title,
    this.description,
    this.type = MarkerType.point,
    this.extraData,
  });
  
  MapMarker copyWith({
    String? id,
    LatLng? position,
    String? title,
    String? description,
    MarkerType? type,
    Map<String, dynamic>? extraData,
  }) {
    return MapMarker(
      id: id ?? this.id,
      position: position ?? this.position,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      extraData: extraData ?? this.extraData,
    );
  }
} 