import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

import '../models/route.dart';
import '../services/route_service.dart';
import '../services/location_service.dart';

class RouteTrackerScreen extends StatefulWidget {
  const RouteTrackerScreen({Key? key}) : super(key: key);

  @override
  State<RouteTrackerScreen> createState() => _RouteTrackerScreenState();
}

class _RouteTrackerScreenState extends State<RouteTrackerScreen> {
  final RouteService _routeService = RouteService();
  final LocationService _locationService = LocationService();
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
                child: _buildStatsView(),
              ),
            ],
          )
        : const Center(
            child: CircularProgressIndicator(),
          ),
      floatingActionButton: _buildActionButton(),
    );
  }
  
  Widget _buildMapView() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: const LatLng(37.7749, -122.4194), // Default center
        initialZoom: 14.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'com.example.osm_app',
        ),
        
        // Draw route polyline
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
          
        // Show start point
        if (_activeRoute != null && _activeRoute!.points.isNotEmpty)
          MarkerLayer(
            markers: [
              // Start marker
              Marker(
                point: _activeRoute!.points.first.position,
                width: 20,
                height: 20,
                child: const Icon(
                  Icons.trip_origin,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              
              // Current position marker
              Marker(
                point: _activeRoute!.points.last.position,
                width: 20,
                height: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
  
  Widget _buildStatsView() {
    final isTracking = _activeRoute != null;
    
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title
          Text(
            isTracking ? _activeRoute!.name : 'Not Tracking',
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
          
          const Spacer(),
          
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
  
  Widget _buildActionButton() {
    final isTracking = _activeRoute != null;
    
    return isTracking
        ? const SizedBox.shrink() // No FAB when tracking
        : FloatingActionButton.extended(
            onPressed: _startTracking,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Tracking'),
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