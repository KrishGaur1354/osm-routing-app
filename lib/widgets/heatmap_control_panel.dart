import 'package:flutter/material.dart';

import '../services/heatmap_service.dart';

class HeatmapControlPanel extends StatefulWidget {
  final Function(HeatmapLayer?) onLayerSelected;
  final VoidCallback onClose;
  
  const HeatmapControlPanel({
    Key? key,
    required this.onLayerSelected,
    required this.onClose,
  }) : super(key: key);

  @override
  State<HeatmapControlPanel> createState() => _HeatmapControlPanelState();
}

class _HeatmapControlPanelState extends State<HeatmapControlPanel> {
  final HeatmapService _heatmapService = HeatmapService();
  List<HeatmapLayer> _layers = [];
  HeatmapLayer? _selectedLayer;
  
  @override
  void initState() {
    super.initState();
    _initialize();
  }
  
  Future<void> _initialize() async {
    await _heatmapService.initialize();
    
    // Listen for layer updates
    _heatmapService.layersStream.listen((layers) {
      setState(() {
        _layers = layers;
        
        // Update selected layer if needed
        if (_selectedLayer != null) {
          try {
            _selectedLayer = layers.firstWhere(
              (layer) => layer.id == _selectedLayer!.id,
            );
          } catch (e) {
            _selectedLayer = layers.isNotEmpty ? layers.first : null;
          }
        }
      });
    });
    
    // Set initial selected layer
    _selectedLayer = _heatmapService.getSelectedLayer();
    if (_selectedLayer != null) {
      widget.onLayerSelected(_selectedLayer);
    }
  }
  
  void _toggleLayerVisibility(String layerId) {
    _heatmapService.toggleLayerVisibility(layerId);
  }
  
  void _selectLayer(HeatmapLayer? layer) {
    setState(() {
      _selectedLayer = layer;
    });
    
    _heatmapService.setSelectedLayer(layer?.id);
    widget.onLayerSelected(layer);
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 4,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Heatmap Layers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onClose,
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Available Layers',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            if (_layers.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _layers.length,
                itemBuilder: (context, index) {
                  final layer = _layers[index];
                  final isSelected = _selectedLayer?.id == layer.id;
                  
                  return _buildLayerItem(layer, isSelected);
                },
              ),
              
            // Layer details section
            if (_selectedLayer != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Selected Layer Details',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              _buildLayerDetails(_selectedLayer!),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildLayerItem(HeatmapLayer layer, bool isSelected) {
    return Card(
      color: isSelected 
          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
          : null,
      elevation: isSelected ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isSelected 
            ? BorderSide(color: Theme.of(context).colorScheme.primary)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _selectLayer(isSelected ? null : layer),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      layer.startColor,
                      layer.endColor,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      layer.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      layer.description,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: layer.isVisible,
                onChanged: (_) => _toggleLayerVisibility(layer.id),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildLayerDetails(HeatmapLayer layer) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              layer.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(layer.description),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Data Points: '),
                Text(
                  '${layer.points.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Heat Radius: '),
                Text(
                  '${layer.radius.toInt()} px',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Color Range: '),
                Container(
                  width: 100,
                  height: 16,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        layer.startColor,
                        layer.endColor,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Visible'),
              value: layer.isVisible,
              onChanged: (_) => _toggleLayerVisibility(layer.id),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
} 