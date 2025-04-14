import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/route.dart';
import '../services/route_service.dart';

class SavedRoutesScreen extends StatefulWidget {
  const SavedRoutesScreen({Key? key}) : super(key: key);

  @override
  State<SavedRoutesScreen> createState() => _SavedRoutesScreenState();
}

class _SavedRoutesScreenState extends State<SavedRoutesScreen> {
  final RouteService _routeService = RouteService();
  List<RouteTrack> _routes = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _initialize();
  }
  
  Future<void> _initialize() async {
    await _routeService.initialize();
    
    _routeService.savedRoutesStream.listen((routes) {
      setState(() {
        _routes = routes;
        _isLoading = false;
      });
    });
    
    setState(() {
      _routes = _routeService.savedRoutes;
      _isLoading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Routes'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _routes.isEmpty
              ? _buildEmptyState()
              : _buildRoutesList(),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.route,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No saved routes yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start tracking a route to save it here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Track New Route'),
            onPressed: () {
              // Navigate to route tracker
              Navigator.pop(context);
              // TODO: Navigate to route tracker
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildRoutesList() {
    return ListView.builder(
      itemCount: _routes.length,
      itemBuilder: (context, index) {
        final route = _routes[index];
        return _buildRouteCard(route);
      },
    );
  }
  
  Widget _buildRouteCard(RouteTrack route) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    final formattedDate = dateFormat.format(route.startTime);
    final distance = (route.totalDistance / 1000).toStringAsFixed(2);
    
    // Format duration
    final hours = route.duration.inHours;
    final minutes = route.duration.inMinutes.remainder(60);
    final formattedDuration = hours > 0 
        ? '$hours hr ${minutes} min'
        : '$minutes min';
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _showRouteDetails(route),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and favorite icon
              Row(
                children: [
                  Expanded(
                    child: Text(
                      route.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      route.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: route.isFavorite ? Colors.red : Colors.grey,
                    ),
                    onPressed: () => _toggleFavorite(route),
                  ),
                ],
              ),
              
              // Date
              Text(
                formattedDate,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat(Icons.straighten, '$distance km'),
                  _buildStat(Icons.timer, formattedDuration),
                  _buildStat(
                    Icons.speed, 
                    '${route.averageSpeed.toStringAsFixed(1)} km/h'
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.map),
                    label: const Text('View Map'),
                    onPressed: () => _viewRouteOnMap(route),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                    onPressed: () => _shareRoute(route),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStat(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  void _toggleFavorite(RouteTrack route) {
    _routeService.updateRoute(
      route.id, 
      isFavorite: !route.isFavorite,
    );
  }
  
  void _showRouteDetails(RouteTrack route) {
    // TODO: Navigate to route details screen
  }
  
  void _viewRouteOnMap(RouteTrack route) {
    // TODO: Show route on map
  }
  
  void _shareRoute(RouteTrack route) {
    // TODO: Share route functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing ${route.name}'),
      ),
    );
  }
} 