import 'package:flutter/material.dart';

class SearchFilters extends StatefulWidget {
  final Function(Map<String, dynamic> filters) onFiltersChanged;
  final Map<String, dynamic> initialFilters;

  const SearchFilters({
    super.key,
    required this.onFiltersChanged,
    this.initialFilters = const {},
  });

  @override
  State<SearchFilters> createState() => _SearchFiltersState();
}

class _SearchFiltersState extends State<SearchFilters> {
  late double _minRating;
  late double _maxRating;
  String? _category;
  String? _specialty;
  double? _minDistance;
  double? _maxDistance;
  String _sortBy = 'rating';

  @override
  void initState() {
    super.initState();
    _minRating = widget.initialFilters['minRating']?.toDouble() ?? 0.0;
    _maxRating = widget.initialFilters['maxRating']?.toDouble() ?? 5.0;
    _category = widget.initialFilters['category'];
    _specialty = widget.initialFilters['specialty'];
    _minDistance = widget.initialFilters['minDistance']?.toDouble();
    _maxDistance = widget.initialFilters['maxDistance']?.toDouble();
    _sortBy = widget.initialFilters['sortBy'] ?? 'rating';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtres de recherche',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // Filtre par note
          const Text('Note minimum'),
          Slider(
            value: _minRating,
            min: 0.0,
            max: 5.0,
            divisions: 10,
            label: _minRating.round().toString(),
            onChanged: (value) {
              setState(() {
                _minRating = value;
              });
              _updateFilters();
            },
          ),
          Text('Minimum: $_minRating/5'),
          
          const SizedBox(height: 16),
          
          // Filtre par catégorie/spécialité
          DropdownButtonFormField<String>(
            value: _category,
            decoration: const InputDecoration(
              labelText: 'Catégorie',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('Toutes les catégories')),
              DropdownMenuItem(value: 'plomberie', child: Text('Plomberie')),
              DropdownMenuItem(value: 'électricité', child: Text('Électricité')),
              DropdownMenuItem(value: 'menuiserie', child: Text('Menuiserie')),
              DropdownMenuItem(value: 'peinture', child: Text('Peinture')),
              DropdownMenuItem(value: 'jardinage', child: Text('Jardinage')),
              DropdownMenuItem(value: 'cuisine', child: Text('Cuisine')),
              DropdownMenuItem(value: 'autres', child: Text('Autres')),
            ],
            onChanged: (value) {
              setState(() {
                _category = value;
              });
              _updateFilters();
            },
          ),
          
          const SizedBox(height: 16),
          
          // Filtre par rayon
          const Text('Distance maximum (km)'),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Min (km)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    if (value.isEmpty) {
                      setState(() {
                        _minDistance = null;
                      });
                    } else {
                      setState(() {
                        _minDistance = double.tryParse(value);
                      });
                    }
                    _updateFilters();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Max (km)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    if (value.isEmpty) {
                      setState(() {
                        _maxDistance = null;
                      });
                    } else {
                      setState(() {
                        _maxDistance = double.tryParse(value);
                      });
                    }
                    _updateFilters();
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Tri
          DropdownButtonFormField<String>(
            value: _sortBy,
            decoration: const InputDecoration(
              labelText: 'Trier par',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'rating', child: Text('Note')),
              DropdownMenuItem(value: 'distance', child: Text('Distance')),
              DropdownMenuItem(value: 'name', child: Text('Nom')),
              DropdownMenuItem(value: 'newest', child: Text('Plus récents')),
            ],
            onChanged: (value) {
              setState(() {
                _sortBy = value!;
              });
              _updateFilters();
            },
          ),
        ],
      ),
    );
  }

  void _updateFilters() {
    final filters = <String, dynamic>{};
    
    if (_minRating > 0) filters['minRating'] = _minRating;
    if (_maxRating < 5) filters['maxRating'] = _maxRating;
    if (_category != null) filters['category'] = _category;
    if (_specialty != null) filters['specialty'] = _specialty;
    if (_minDistance != null) filters['minDistance'] = _minDistance;
    if (_maxDistance != null) filters['maxDistance'] = _maxDistance;
    if (_sortBy != 'rating') filters['sortBy'] = _sortBy;
    
    widget.onFiltersChanged(filters);
  }
}