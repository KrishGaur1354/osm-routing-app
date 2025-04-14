import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

import '../models/route.dart';
import '../services/route_service.dart';
import '../services/location_service.dart';
import '../services/distance_calculator_service.dart';

class RouteTrackerScreen extends StatefulWidget {
  const RouteTrackerScreen({Key? key}) : super(key: key);

  @override
  State<RouteTrackerScreen> createState() => _RouteTrackerScreenState();
}

class _RouteTrackerScreenState extends State<RouteTrackerScreen> {
  final RouteService _routeService = RouteService();
  final LocationService _locationService = LocationService();
  final DistanceCalculatorService _distanceCalculator = DistanceCalculatorService();
  final MapController _mapController = MapController();
  
  // State variables
  RouteTrack? _activeRoute;
  bool _isInitialized = false;
  bool _isPaused = false;
  late Timer _statsUpdateTimer;

  // Stats display
  Duration _duration = Duration.zero;
  double _distance = 0.0;
  double _avgSpeed = 0.0;
  
  // Distance and time between points
  LatLng? _selectedStartPoint;
  LatLng? _selectedEndPoint;
  double _selectedDistance = 0.0;
  Duration _selectedDuration = Duration.zero;
  TransportMode _selectedTransportMode = TransportMode.walking;
  
  @override
  void initState() {
    super.initState();
    _initialize();
    
    // Set up timer to update stats
    _statsUpdateTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateStats(),
    );
  }
  
  Future<void> _initialize() async {
    await _routeService.initialize();
    
    // Listen for route updates
    _routeService.currentRouteStream.listen((route) {
      setState(() {
        _activeRoute = route;
        _updateStats();
      });
      
      // If we have a route, focus map on it
      if (route != null && route.points.isNotEmpty) {
        _focusOnRoute(route);
      }
    });
    
    setState(() {
      _isInitialized = true;
    });
  }
  
  void _updateStats() {
    if (_activeRoute == null) {
      setState(() {
        _duration = Duration.zero;
        _distance = 0.0;
        _avgSpeed = 0.0;
      });
      return;
    }
    
    setState(() {
      _duration = _activeRoute!.duration;
      _distance = _activeRoute!.totalDistance;
      _avgSpeed = _activeRoute!.averageSpeed;
    });
  }
  
  void _focusOnRoute(RouteTrack route) {
    if (route.points.isEmpty) return;
    
    // Get the most recent point
    final lastPoint = route.points.last.position;
    
    // Move map to this point
    _mapController.move(lastPoint, 16.0);
  }
  
  Future<void> _startTracking() async {
    // Show dialog to name the route
    final routeName = await _showNameRouteDialog();
    if (routeName == null || routeName.isEmpty) return;
    
    // Start tracking
    await _routeService.startRouteTracking(
      routeName,
      description: 'Tracked on ${DateTime.now().toLocal().toString().split(' ')[0]}',
    );
  }
  
  Future<void> _stopTracking() async {
    // Confirm user wants to stop
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop Tracking?'),
        content: const Text('This will end the current route tracking. The route will be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Stop Tracking'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      final route = await _routeService.stopRouteTracking();
      if (route != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Route "${route.name}" saved!'),
            action: SnackBarAction(
              label: 'View',
              onPressed: () {
                // Navigate to route details screen
                // TODO: Implement navigation to route details
              },
            ),
          ),
        );
      }
    }
  }
  
  Future<String?> _showNameRouteDialog() async {
    final TextEditingController nameController = TextEditingController(
      text: 'Route ${DateTime.now().toString().split(' ')[0]}'
    );
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Name Your Route'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Route Name',
            hintText: 'Enter a name for this route',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, nameController.text),
            child: const Text('Start Tracking'),
          ),
        ],
      ),
    );
  }
  
  void _selectStartPoint(LatLng point) {
    setState(() {
      _selectedStartPoint = point;
      _calculateSelectedRoute();
    });
  }
  
  void _selectEndPoint(LatLng point) {
    setState(() {
      _selectedEndPoint = point;
      _calculateSelectedRoute();
    });
  }
  
  void _calculateSelectedRoute() {
    if (_selectedStartPoint != null && _selectedEndPoint != null) {
      final distance = _distanceCalculator.calculateDistance(
        _selectedStartPoint!,
        _selectedEndPoint!,
      );
      
      setState(() {
        _selectedDistance = distance;
        _selectedDuration = _distanceCalculator.estimateTravelTime(
          distance, 
          _selectedTransportMode,
        );
      });
    }
  }
  
  void _changeTransportMode(TransportMode mode) {
    setState(() {
      _selectedTransportMode = mode;
      _calculateSelectedRoute();
    });
  }
  
  @override
  void dispose() {
    _statsUpdateTimer.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Tracker'),
        centerTitle: true,
      ),
      body: _isInitialized 
        ? Column(
            children: [
              // Map view (top 60%)
              Expanded(
                flex: 6,
                child: _buildMapView(),
              ),
              
              // Stats view (bottom 40%)
              Expanded(
                flex: 4,
                child: SingleChildScrollView(
                  child: _activeRoute != null 
                    ? _buildActiveRouteStats() 
                    : _buildDistanceCalculator(),
                ),
              ),
            ],
          )
        : const Center(child: CircularProgressIndicator()),
    );
  }
  
  Widget _buildMapView() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _activeRoute?.points.isNotEmpty == true 
            ? _activeRoute!.points.last.position 
            : const LatLng(0, 0),
        initialZoom: 15.0,
        onTap: (_, point) {
          // Handle map tap
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.osm_app',
        ),
        MarkerLayer(
          markers: _buildMarkersForMap(),
        ),
        if (_activeRoute?.points.isNotEmpty == true)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _activeRoute!.points.map((p) => p.position).toList(),
                color: Colors.blue,
                strokeWidth: 4.0,
              ),
            ],
          ),
      ],
    );
  }
  
  List<Marker> _buildMarkersForMap() {
    final List<Marker> markers = [];
    
    // Add current position marker if we have one
    if (_activeRoute?.points.isNotEmpty == true) {
      final lastPoint = _activeRoute!.points.last.position;
      markers.add(
        Marker(
          point: lastPoint,
          width: 25,
          height: 25,
          child: const Icon(
            Icons.location_on,
            color: Colors.red,
            size: 25,
          ),
        ),
      );
    }
    
    // Add start/end point markers if selected
    if (_selectedStartPoint != null) {
      markers.add(
        Marker(
          point: _selectedStartPoint!,
          width: 25,
          height: 25,
          child: const Icon(
            Icons.play_circle,
            color: Colors.green,
            size: 25,
          ),
        ),
      );
    }
    
    if (_selectedEndPoint != null) {
      markers.add(
        Marker(
          point: _selectedEndPoint!,
          width: 25,
          height: 25,
          child: const Icon(
            Icons.stop_circle,
            color: Colors.red,
            size: 25,
          ),
        ),
      );
    }
    
    return markers;
  }
  
  Widget _buildActiveRouteStats() {
    final isTracking = _activeRoute != null;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title
          Text(
            _activeRoute!.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                title: 'Distance',
                value: '${(_distance / 1000).toStringAsFixed(2)} km',
                icon: Icons.straighten,
              ),
              _buildStatCard(
                title: 'Duration',
                value: _formatDuration(_duration),
                icon: Icons.timer,
              ),
              _buildStatCard(
                title: 'Avg. Speed',
                value: '${_avgSpeed.toStringAsFixed(1)} km/h',
                icon: Icons.speed,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Action buttons
          if (isTracking)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _stopTracking,
                ),
                
                ElevatedButton.icon(
                  icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                  label: Text(_isPaused ? 'Resume' : 'Pause'),
                  onPressed: () {
                    // TODO: Implement pause functionality
                    setState(() {
                      _isPaused = !_isPaused;
                    });
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }
  
  Widget _buildDistanceCalculator() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Distance Calculator',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildLocationCard(
                  'Start',
                  _selectedStartPoint != null
                    ? '${_selectedStartPoint!.latitude.toStringAsFixed(4)}, ${_selectedStartPoint!.longitude.toStringAsFixed(4)}'
                    : 'Select on map',
                  Icons.location_on,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildLocationCard(
                  'End',
                  _selectedEndPoint != null
                    ? '${_selectedEndPoint!.latitude.toStringAsFixed(4)}, ${_selectedEndPoint!.longitude.toStringAsFixed(4)}'
                    : 'Select on map',
                  Icons.flag,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTransportSelector(),
          const SizedBox(height: 16),
          _buildCalculationResults(),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _startTracking(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('START TRACKING NEW ROUTE'),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLocationCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTransportSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildTransportOption(TransportMode.walking, Icons.directions_walk, 'Walk'),
        _buildTransportOption(TransportMode.cycling, Icons.directions_bike, 'Cycle'),
        _buildTransportOption(TransportMode.driving, Icons.directions_car, 'Drive'),
        _buildTransportOption(TransportMode.transit, Icons.directions_bus, 'Transit'),
      ],
    );
  }
  
  Widget _buildTransportOption(TransportMode mode, IconData icon, String label) {
    final isSelected = _selectedTransportMode == mode;
    
    return InkWell(
      onTap: () => _changeTransportMode(mode),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.2) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Theme.of(context).colorScheme.primary : null,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Theme.of(context).colorScheme.primary : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCalculationResults() {
    if (_selectedStartPoint == null || _selectedEndPoint == null) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text('Select start and end points on the map'),
      );
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildResultItem(
              'Distance',
              _distanceCalculator.formatDistance(_selectedDistance),
              Icons.straighten,
            ),
            _buildResultItem(
              'Est. Time',
              _distanceCalculator.formatDuration(_selectedDuration),
              Icons.timer,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildResultItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }
} 