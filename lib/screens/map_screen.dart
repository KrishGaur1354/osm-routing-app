import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';

import '../models/map_marker.dart';
import '../models/poi.dart';
import '../services/location_service.dart';
import '../services/poi_service.dart';
import '../services/route_planning_service.dart';
import '../services/heatmap_service.dart';
import '../services/distance_calculator_service.dart';
import '../widgets/custom_marker.dart';
import '../widgets/map_control_panel.dart';
import '../widgets/search_panel.dart';
import '../widgets/route_planner.dart';
import '../widgets/heatmap_layer.dart';
import '../widgets/heatmap_control_panel.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final LocationService _locationService = LocationService();
  final POIService _poiService = POIService();
  final RoutePlanningService _routePlanningService = RoutePlanningService();
  final HeatmapService _heatmapService = HeatmapService();
  final DistanceCalculatorService _distanceCalculator = DistanceCalculatorService();
  final MapController _mapController = MapController();
  
  // Default center position (Delhi)
  late LatLng _center;
  
  // Map style/source options
  String _currentMapStyle = 'streets';
  final Map<String, String> _mapStyles = {
    'streets': 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
    'topographic': 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
    'dark': 'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}.png',
    'satellite': 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
  };
  
  // Markers
  final List<Marker> _markers = [];
  final List<MapMarker> _savedMarkers = [];
  List<POI> _displayedPOIs = [];
  double _currentZoom = 13.0;
  
  // Routes
  PlannedRoute? _activeRoute;
  LatLng? _routeDestination;
  
  // Heatmap
  List<HeatmapLayer> _heatmapLayers = [];
  HeatmapLayer? _activeHeatmapLayer;
  
  // UI control flags
  bool _isFollowingUser = true;
  bool _isShowingTraffic = false;
  bool _isInEditMode = false;
  bool _isSearchVisible = false;
  bool _isRoutePlannerVisible = false;
  bool _isHeatmapControlVisible = false;
  
  @override
  void initState() {
    super.initState();
    // Set default center to Pitampura, Delhi
    _center = _distanceCalculator.delhiLocation;
    _initializeLocation();
    _initializePOIs();
    _initializeRoutes();
    _initializeHeatmaps();
  }
  
  Future<void> _initializeLocation() async {
    // Request location permission
    await _locationService.requestLocationPermission();
    
    // Get current position
    Position? position = await _locationService.getCurrentPosition();
    if (position != null) {
      setState(() {
        _center = LatLng(position.latitude, position.longitude);
        _addUserLocationMarker(position);
      });
      
      _animatedMapMove(_center, _currentZoom);
    }
    
    // Start listening to location updates
    _locationService.startLocationUpdates();
    _locationService.locationStream.listen(_handleLocationUpdate);
  }

  Future<void> _initializePOIs() async {
    await _poiService.initialize();
    
    // Listen for POI updates
    _poiService.poisStream.listen((pois) {
      setState(() {
        _displayedPOIs = pois;
        _refreshAllMarkers();
      });
    });
  }
  
  Future<void> _initializeRoutes() async {
    await _routePlanningService.initialize();
    
    // Listen for route updates
    _routePlanningService.routesStream.listen((routes) {
      // Update active route if it's in the routes list
      if (_activeRoute != null) {
        final updatedActiveRoute = routes.firstWhere(
          (route) => route.id == _activeRoute!.id,
          orElse: () => _activeRoute!,
        );
        
        if (updatedActiveRoute.id != _activeRoute!.id) {
          setState(() {
            _activeRoute = updatedActiveRoute;
          });
        }
      }
    });
  }
  
  Future<void> _initializeHeatmaps() async {
    await _heatmapService.initialize();
    
    // Listen for heatmap updates
    _heatmapService.layersStream.listen((layers) {
      setState(() {
        _heatmapLayers = layers;
        
        // Update active layer if needed
        if (_activeHeatmapLayer != null) {
          final foundLayer = layers.where(
            (layer) => layer.id == _activeHeatmapLayer!.id && layer.isVisible).toList();
          
          if (foundLayer.isNotEmpty) {
            _activeHeatmapLayer = foundLayer.first;
          } else {
            _activeHeatmapLayer = null;
          }
        }
      });
    });
  }
  
  void _handleLocationUpdate(Position position) {
    LatLng newLocation = LatLng(position.latitude, position.longitude);
    
    // Update user marker
    setState(() {
      // Remove previous user marker
      _markers.removeWhere((marker) => marker.key.toString().contains('user_location'));
      
      // Add new user marker
      _addUserLocationMarker(position);
    });
    
    // If following user, move the map to the user's location
    if (_isFollowingUser) {
      _animatedMapMove(newLocation, _currentZoom);
    }
  }
  
  void _addUserLocationMarker(Position position) {
    final userLocation = LatLng(position.latitude, position.longitude);
    final userMarker = Marker(
      key: const Key('user_location'),
      point: userLocation,
      width: 60,
      height: 60,
      child: const CustomMarker(markerType: MarkerType.user),
    );
    
    _markers.add(userMarker);
  }
  
  void _addCustomMarker(LatLng position, MarkerType type) {
    final newMarkerId = 'marker_${DateTime.now().millisecondsSinceEpoch}';
    
    // Create model
    final mapMarker = MapMarker(
      id: newMarkerId,
      position: position,
      type: type,
      title: 'New Marker',
      description: 'Tap to edit',
    );
    
    // Save to list
    setState(() {
      _savedMarkers.add(mapMarker);
      _refreshAllMarkers();
    });
  }
  
  void _refreshAllMarkers() {
    // Keep only user location marker
    _markers.removeWhere((marker) => !marker.key.toString().contains('user_location'));
    
    // Add all saved markers
    for (var marker in _savedMarkers) {
      _markers.add(
        Marker(
          key: Key(marker.id),
          point: marker.position,
          width: 50,
          height: 50,
          child: GestureDetector(
            onTap: () => _showMarkerDetails(marker),
            child: CustomMarker(markerType: marker.type),
          ),
        ),
      );
    }
    
    // Add POI markers
    for (var poi in _displayedPOIs) {
      _markers.add(
        Marker(
          key: Key('poi_${poi.id}'),
          point: poi.position,
          width: 50,
          height: 50,
          child: GestureDetector(
            onTap: () => _showPOIDetails(poi),
            child: Icon(
              _getPOIIcon(poi.category),
              color: Color(POI.getCategoryColor(poi.category)),
              size: 30,
            ),
          ),
        ),
      );
    }
  }
  
  IconData _getPOIIcon(POICategory category) {
    // Convert string icon name to IconData
    switch (category) {
      case POICategory.restaurant:
        return Icons.restaurant;
      case POICategory.hotel:
        return Icons.hotel;
      case POICategory.cafe:
        return Icons.local_cafe;
      case POICategory.attraction:
        return Icons.attractions;
      case POICategory.shopping:
        return Icons.shopping_bag;
      case POICategory.gas:
        return Icons.local_gas_station;
      case POICategory.parking:
        return Icons.local_parking;
      case POICategory.hospital:
        return Icons.local_hospital;
      case POICategory.pharmacy:
        return Icons.local_pharmacy;
      case POICategory.bank:
        return Icons.account_balance;
      case POICategory.other:
        return Icons.place;
    }
  }
  
  void _showMarkerDetails(MapMarker marker) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(marker.title ?? 'Unnamed Marker', 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(marker.description ?? 'No description'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                  onPressed: () {
                    Navigator.pop(context);
                    // TODO: Show edit dialog
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.directions),
                  label: const Text('Directions'),
                  onPressed: () {
                    Navigator.pop(context);
                    // TODO: Show directions
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete'),
                  onPressed: () {
                    setState(() {
                      _savedMarkers.removeWhere((m) => m.id == marker.id);
                      _refreshAllMarkers();
                    });
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  void _showPOIDetails(POI poi) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getPOIIcon(poi.category),
                  color: Color(POI.getCategoryColor(poi.category)),
                  size: 30,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    poi.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ),
                if (poi.rating != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          poi.rating!.toStringAsFixed(1),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (poi.address != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(child: Text(poi.address!, style: const TextStyle(color: Colors.grey))),
                  ],
                ),
              ),
            if (poi.description != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(poi.description!),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.directions),
                  label: const Text('Directions'),
                  onPressed: () {
                    Navigator.pop(context);
                    _showRoutePlanner(poi.position);
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                  onPressed: () {
                    Navigator.pop(context);
                    // TODO: Implement share functionality
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.bookmark_border),
                  label: const Text('Save'),
                  onPressed: () {
                    Navigator.pop(context);
                    // TODO: Implement save functionality
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  void _showRoutePlanner(LatLng destination) {
    // Get current user location
    final userMarker = _markers.firstWhere(
      (marker) => marker.key.toString().contains('user_location'),
      orElse: () => Marker(
        key: const Key('default'),
        point: _center,
        child: Container(),
      ),
    );
    
    setState(() {
      _routeDestination = destination;
      _isRoutePlannerVisible = true;
    });
  }
  
  void _onRouteSelected(PlannedRoute route) {
    setState(() {
      _activeRoute = route;
      _isRoutePlannerVisible = false;
      
      // Zoom to show the entire route
      _zoomToShowMarkers(route.points.map((point) => point.position).toList());
    });
  }
  
  void _clearActiveRoute() {
    setState(() {
      _activeRoute = null;
      _routeDestination = null;
    });
  }
  
  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final latTween = Tween<double>(
      begin: _mapController.camera.center.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: _mapController.camera.center.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(
      begin: _mapController.camera.zoom,
      end: destZoom,
    );

    final controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    final Animation<double> animation = CurvedAnimation(
      parent: controller,
      curve: Curves.fastOutSlowIn,
    );

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
      } else if (status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }
  
  void _changeMapStyle(String styleKey) {
    setState(() {
      _currentMapStyle = styleKey;
    });
  }
  
  void _toggleFollowUser() {
    setState(() {
      _isFollowingUser = !_isFollowingUser;
      
      if (_isFollowingUser) {
        // Find user marker and center map on it
        final userMarker = _markers.firstWhere(
          (marker) => marker.key.toString().contains('user_location'),
          orElse: () => Marker(
            key: const Key('default'),
            point: _center,
            child: Container(),
          ),
        );
        
        _animatedMapMove(userMarker.point, _currentZoom);
      }
    });
  }
  
  void _toggleEditMode() {
    setState(() {
      _isInEditMode = !_isInEditMode;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isInEditMode
          ? 'Edit mode enabled. Tap on the map to add markers.'
          : 'Edit mode disabled'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  void _toggleSearchPanel() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
    });
  }
  
  void _toggleRoutePlanner() {
    setState(() {
      _isRoutePlannerVisible = !_isRoutePlannerVisible;
      
      // If closing, clear the destination
      if (!_isRoutePlannerVisible) {
        _routeDestination = null;
      }
    });
  }
  
  void _toggleHeatmapControl() {
    setState(() {
      _isHeatmapControlVisible = !_isHeatmapControlVisible;
    });
  }
  
  void _onSearchResults(List<POI> results) {
    setState(() {
      _displayedPOIs = results;
      _refreshAllMarkers();
      
      // If we have results, zoom to show them all
      if (results.isNotEmpty) {
        _zoomToShowMarkers(results.map((poi) => poi.position).toList());
      }
    });
  }
  
  void _zoomToShowMarkers(List<LatLng> points) {
    if (points.isEmpty) return;
    
    // If there's only one point, just center on it
    if (points.length == 1) {
      _animatedMapMove(points.first, 15.0);
      return;
    }
    
    // Find the bounds that include all points
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;
    
    for (var point in points) {
      minLat = min(minLat, point.latitude);
      maxLat = max(maxLat, point.latitude);
      minLng = min(minLng, point.longitude);
      maxLng = max(maxLng, point.longitude);
    }
    
    // Add some padding
    final latPadding = (maxLat - minLat) * 0.1;
    final lngPadding = (maxLng - minLng) * 0.1;
    
    minLat -= latPadding;
    maxLat += latPadding;
    minLng -= lngPadding;
    maxLng += lngPadding;
    
    // Calculate center
    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;
    
    // Estimate zoom level based on bounds
    final latZoom = _getZoomLevel(minLat, maxLat);
    final lngZoom = _getZoomLevel(minLng, maxLng);
    final zoom = min(latZoom, lngZoom);
    
    _animatedMapMove(LatLng(centerLat, centerLng), zoom);
  }
  
  double _getZoomLevel(double min, double max) {
    final delta = max - min;
    if (delta <= 0) return 15.0;
    
    // This is a heuristic formula to estimate zoom level based on delta
    return 14.0 - (math.log(delta * 111) / math.log(2));
  }
  
  double min(double a, double b) => a < b ? a : b;
  double max(double a, double b) => a > b ? a : b;
  
  void _onMapTap(TapPosition tapPosition, LatLng point) {
    if (_isInEditMode) {
      _addCustomMarker(point, MarkerType.point);
    }
  }
  
  void _onHeatmapLayerSelected(HeatmapLayer? layer) {
    setState(() {
      _activeHeatmapLayer = layer;
    });
  }
  
  @override
  void dispose() {
    _locationService.dispose();
    _poiService.dispose();
    _routePlanningService.dispose();
    _heatmapService.dispose();
    _mapController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OpenStreetMap Explorer'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isSearchVisible ? Icons.close : Icons.search),
            onPressed: _toggleSearchPanel,
          ),
          IconButton(
            icon: Icon(_isRoutePlannerVisible ? Icons.close : Icons.directions),
            onPressed: _toggleRoutePlanner,
          ),
          IconButton(
            icon: Icon(_isHeatmapControlVisible ? Icons.layers_clear : Icons.layers),
            onPressed: _toggleHeatmapControl,
            tooltip: 'Data Layers',
          ),
          PopupMenuButton<String>(
            onSelected: _changeMapStyle,
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'streets',
                  child: Text('Streets'),
                ),
                const PopupMenuItem<String>(
                  value: 'topographic',
                  child: Text('Topographic'),
                ),
                const PopupMenuItem<String>(
                  value: 'dark',
                  child: Text('Dark'),
                ),
                const PopupMenuItem<String>(
                  value: 'satellite',
                  child: Text('Satellite'),
                ),
              ];
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: _currentZoom,
              onTap: _onMapTap,
              onPositionChanged: (position, hasGesture) {
                setState(() {
                  _currentZoom = position.zoom;
                  
                  // If user manually moves the map, disable follow mode
                  if (hasGesture && _isFollowingUser) {
                    _isFollowingUser = false;
                  }
                });
              },
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: _mapStyles[_currentMapStyle],
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.osm_app',
              ),
              
              // Display active route if any
              if (_activeRoute != null && _activeRoute!.points.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _activeRoute!.points.map((p) => p.position).toList(),
                      color: _activeRoute!.color,
                      strokeWidth: 4.0,
                    ),
                  ],
                ),
              
              // Display active heatmap layer if any
              if (_activeHeatmapLayer != null && _activeHeatmapLayer!.isVisible)
                HeatmapLayerWidget(layer: _activeHeatmapLayer!),
              
              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  maxClusterRadius: 120,
                  size: const Size(40, 40),
                  markers: _markers,
                  builder: (context, markers) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Theme.of(context).primaryColor,
                      ),
                      child: Center(
                        child: Text(
                          markers.length.toString(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Route end marker
              if (_routeDestination != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _routeDestination!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.place,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          
          // Search panel
          if (_isSearchVisible)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SearchPanel(
                onSearchResults: _onSearchResults,
                onClose: _toggleSearchPanel,
              ),
            ),
            
          // Route planner panel
          if (_isRoutePlannerVisible) 
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: RoutePlanner(
                startPoint: _getUserLocation(),
                endPoint: _routeDestination,
                onRouteSelected: _onRouteSelected,
                onClose: _toggleRoutePlanner,
              ),
            ),
            
          // Heatmap control panel
          if (_isHeatmapControlVisible)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: HeatmapControlPanel(
                onLayerSelected: _onHeatmapLayerSelected,
                onClose: _toggleHeatmapControl,
              ),
            ),
          
          // Active route info
          if (_activeRoute != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Icon(_activeRoute!.modeIcon, color: _activeRoute!.color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_activeRoute!.formattedDistance} • ${_activeRoute!.formattedDuration}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Arrival at ${_getArrivalTime(_activeRoute!.totalDuration)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _clearActiveRoute,
                        iconSize: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // Map control panel
          Positioned(
            bottom: 16,
            right: 16,
            child: MapControlPanel(
              onEditToggle: _toggleEditMode,
              isEditMode: _isInEditMode,
              onZoomIn: () {
                final newZoom = _currentZoom + 1;
                setState(() {
                  _currentZoom = newZoom.clamp(3.0, 19.0);
                });
                _mapController.move(_mapController.camera.center, _currentZoom);
              },
              onZoomOut: () {
                final newZoom = _currentZoom - 1;
                setState(() {
                  _currentZoom = newZoom.clamp(3.0, 19.0);
                });
                _mapController.move(_mapController.camera.center, _currentZoom);
              },
              onMyLocation: () {
                _toggleFollowUser();
                
                // If we weren't already following, find and center on user
                if (!_isFollowingUser) {
                  _toggleFollowUser();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
  
  LatLng _getUserLocation() {
    // Find user marker
    final userMarker = _markers.firstWhere(
      (marker) => marker.key.toString().contains('user_location'),
      orElse: () => Marker(
        key: const Key('default'),
        point: _center,
        child: Container(),
      ),
    );
    
    return userMarker.point;
  }
  
  String _getArrivalTime(Duration duration) {
    final now = DateTime.now();
    final arrival = now.add(duration);
    
    // Format time as HH:MM
    final hour = arrival.hour.toString().padLeft(2, '0');
    final minute = arrival.minute.toString().padLeft(2, '0');
    
    return '$hour:$minute';
  }
}

// Extension for string capitalization
extension StringExtension on String {
  String capitalize() {
    return isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
  }
} 