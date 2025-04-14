import 'package:flutter/material.dart';
import '../models/poi.dart';
import '../services/poi_service.dart';

class SearchPanel extends StatefulWidget {
  final Function(List<POI>) onSearchResults;
  final VoidCallback onClose;
  
  const SearchPanel({
    Key? key,
    required this.onSearchResults,
    required this.onClose,
  }) : super(key: key);

  @override
  State<SearchPanel> createState() => _SearchPanelState();
}

class _SearchPanelState extends State<SearchPanel> {
  final POIService _poiService = POIService();
  final TextEditingController _searchController = TextEditingController();
  
  List<POICategory> _selectedCategories = [];
  double _radiusKm = 2.0;
  double? _minRating;
  bool _isAdvancedSearch = false;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _initialize();
  }
  
  Future<void> _initialize() async {
    await _poiService.initialize();
    _performSearch();
  }
  
  void _performSearch() {
    setState(() {
      _isLoading = true;
    });
    
    final results = _poiService.advancedSearch(
      textQuery: _searchController.text,
      categories: _selectedCategories.isEmpty ? null : _selectedCategories,
      minRating: _minRating,
      // Location filters are applied in the map screen
    );
    
    setState(() {
      _isLoading = false;
    });
    
    widget.onSearchResults(results);
  }
  
  void _toggleCategory(POICategory category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else {
        _selectedCategories.add(category);
      }
    });
    _performSearch();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: widget.onClose,
              ),
              Expanded(
                child: Text(
                  'Search Points of Interest',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                icon: Icon(_isAdvancedSearch ? Icons.expand_less : Icons.expand_more),
                onPressed: () {
                  setState(() {
                    _isAdvancedSearch = !_isAdvancedSearch;
                  });
                },
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Search box
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search restaurants, hotels, etc.',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _performSearch();
                      },
                    )
                  : null,
            ),
            onChanged: (_) => _performSearch(),
          ),
          
          // Category chips
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: POICategory.values.map((category) {
                final isSelected = _selectedCategories.contains(category);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category.toString().split('.').last),
                    selected: isSelected,
                    onSelected: (_) => _toggleCategory(category),
                    backgroundColor: Colors.grey[200],
                    selectedColor: Color(POI.getCategoryColor(category)).withOpacity(0.3),
                  ),
                );
              }).toList(),
            ),
          ),
          
          // Advanced search options
          if (_isAdvancedSearch) ...[
            const Divider(),
            
            const SizedBox(height: 8),
            
            // Radius slider
            Row(
              children: [
                const Text('Radius:'),
                Expanded(
                  child: Slider(
                    value: _radiusKm,
                    min: 0.5,
                    max: 10.0,
                    divisions: 19,
                    label: '${_radiusKm.toStringAsFixed(1)} km',
                    onChanged: (value) {
                      setState(() {
                        _radiusKm = value;
                      });
                      // Don't trigger search here as we apply radius in the map
                    },
                  ),
                ),
                Text('${_radiusKm.toStringAsFixed(1)} km'),
              ],
            ),
            
            // Rating filter
            Row(
              children: [
                const Text('Min rating:'),
                Expanded(
                  child: Slider(
                    value: _minRating ?? 0,
                    min: 0,
                    max: 5,
                    divisions: 10,
                    label: _minRating == null 
                        ? 'Any' 
                        : _minRating!.toStringAsFixed(1),
                    onChanged: (value) {
                      setState(() {
                        _minRating = value == 0 ? null : value;
                      });
                      _performSearch();
                    },
                  ),
                ),
                Text(_minRating == null ? 'Any' : _minRating!.toStringAsFixed(1)),
              ],
            ),
          ],
          
          const SizedBox(height: 8),
          
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
} 