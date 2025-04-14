import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../models/poi.dart';
import '../services/route_planning_service.dart';

class RoutePlanner extends StatefulWidget {
  final LatLng startPoint;
  final LatLng? endPoint;
  final Function(PlannedRoute) onRouteSelected;
  final VoidCallback onClose;
  
  const RoutePlanner({
    Key? key,
    required this.startPoint,
    this.endPoint,
    required this.onRouteSelected,
    required this.onClose,
  }) : super(key: key);

  @override
  State<RoutePlanner> createState() => _RoutePlannerState();
}

class _RoutePlannerState extends State<RoutePlanner> {
  final RoutePlanningService _routeService = RoutePlanningService();
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  
  late LatLng _startPoint;
  LatLng? _endPoint;
  
  TransportMode _selectedMode = TransportMode.driving;
  bool _isLoading = false;
  List<RouteAlternative> _routeAlternatives = [];
  
  @override
  void initState() {
    super.initState();
    _startPoint = widget.startPoint;
    _endPoint = widget.endPoint;
    
    // Set initial text for controllers
    _startController.text = 'Current Location';
    if (_endPoint != null) {
      _endController.text = 'Selected Destination';
      _calculateRoute();
    }
  }
  
  void _calculateRoute() async {
    // Need both start and end points
    if (_endPoint == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final alternatives = await _routeService.planRoute(
        _startPoint, 
        _endPoint!, 
        _selectedMode,
      );
      
      setState(() {
        _routeAlternatives = alternatives;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error calculating route: $e')),
        );
      }
    }
  }
  
  void _selectTransportMode(TransportMode mode) {
    setState(() {
      _selectedMode = mode;
    });
    _calculateRoute();
  }
  
  void _selectRoute(RouteAlternative alternative) {
    widget.onRouteSelected(alternative.route);
    
    // Close the panel
    widget.onClose();
  }
  
  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBar(
            title: const Text('Route Planner'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: widget.onClose,
            ),
            centerTitle: true,
          ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Start and end points
                TextField(
                  controller: _startController,
                  decoration: InputDecoration(
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green.shade100,
                      ),
                      child: const Icon(Icons.trip_origin, color: Colors.green),
                    ),
                    hintText: 'Choose starting point',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  readOnly: true,
                ),
                
                const SizedBox(height: 8),
                
                TextField(
                  controller: _endController,
                  decoration: InputDecoration(
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red.shade100,
                      ),
                      child: const Icon(Icons.place, color: Colors.red),
                    ),
                    hintText: 'Choose destination',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  readOnly: true,
                ),
                
                const SizedBox(height: 16),
                
                // Transport mode selection
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTransportModeButton(TransportMode.driving),
                    _buildTransportModeButton(TransportMode.transit),
                    _buildTransportModeButton(TransportMode.cycling),
                    _buildTransportModeButton(TransportMode.walking),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_routeAlternatives.isNotEmpty)
                  // Route alternatives
                  Column(
                    children: _routeAlternatives.map((alternative) => 
                      _buildRouteAlternativeCard(alternative)
                    ).toList(),
                  )
                else if (_endPoint != null)
                  const Text('No routes found. Try a different transport mode.')
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTransportModeButton(TransportMode mode) {
    final bool isSelected = _selectedMode == mode;
    IconData icon;
    String label;
    
    switch (mode) {
      case TransportMode.driving:
        icon = Icons.directions_car;
        label = 'Car';
        break;
      case TransportMode.transit:
        icon = Icons.directions_bus;
        label = 'Transit';
        break;
      case TransportMode.cycling:
        icon = Icons.directions_bike;
        label = 'Bike';
        break;
      case TransportMode.walking:
        icon = Icons.directions_walk;
        label = 'Walk';
        break;
    }
    
    return InkWell(
      onTap: () => _selectTransportMode(mode),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRouteAlternativeCard(RouteAlternative alternative) {
    final route = alternative.route;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _selectRoute(alternative),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(route.modeIcon, color: route.color),
                  const SizedBox(width: 8),
                  Text(
                    alternative.description,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route.formattedDuration,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Arrival at ${_getArrivalTime(route.totalDuration)}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    route.formattedDistance,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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