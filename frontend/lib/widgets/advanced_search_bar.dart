import 'package:flutter/material.dart';
import 'package:frontend/services/advanced_search_service.dart';
import 'package:frontend/widgets/search_filters.dart';

class AdvancedSearchBar extends StatefulWidget {
  final Function(String query, Map<String, dynamic> filters) onSearch;
  final String hintText;
  final bool showFilters;

  const AdvancedSearchBar({
    super.key,
    required this.onSearch,
    this.hintText = 'Rechercher des artisans ou commerçants...',
    this.showFilters = true,
  });

  @override
  State<AdvancedSearchBar> createState() => _AdvancedSearchBarState();
}

class _AdvancedSearchBarState extends State<AdvancedSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final AdvancedSearchService _searchService = AdvancedSearchService();
  final FocusNode _focusNode = FocusNode();
  bool _showSuggestions = false;
  List<String> _suggestions = [];
  Map<String, dynamic> _filters = {};

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _showSuggestions = _focusNode.hasFocus && _controller.text.isNotEmpty;
    });
  }

  Future<void> _onTextChanged(String value) async {
    if (value.length > 2) {
      try {
        _suggestions = await _searchService.getSearchSuggestions(value);
        setState(() {
          _showSuggestions = _focusNode.hasFocus;
        });
      } catch (e) {
        setState(() {
          _suggestions = [];
        });
      }
    } else {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
    }
  }

  void _onSearchSubmitted(String value) {
    widget.onSearch(value, _filters);
    _showSuggestions = false;
    FocusScope.of(context).unfocus();
  }

  void _onFilterChanged(Map<String, dynamic> filters) {
    setState(() {
      _filters = filters;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barre de recherche
        Container(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            decoration: InputDecoration(
              hintText: widget.hintText,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _controller.clear();
                        setState(() {
                          _suggestions = [];
                          _showSuggestions = false;
                        });
                      },
                    )
                  : widget.showFilters
                      ? IconButton(
                          icon: const Icon(Icons.filter_alt),
                          onPressed: () {
                            _showFiltersDialog();
                          },
                        )
                      : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24.0),
              ),
              filled: true,
              fillColor: Theme.of(context).cardColor,
            ),
            onChanged: _onTextChanged,
            onSubmitted: _onSearchSubmitted,
          ),
        ),
        
        // Suggestions de recherche
        if (_showSuggestions && _suggestions.isNotEmpty)
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 200),
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const Icon(Icons.search),
                    title: Text(_suggestions[index]),
                    onTap: () {
                      _controller.text = _suggestions[index];
                      _onSearchSubmitted(_suggestions[index]);
                    },
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  void _showFiltersDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          Map<String, dynamic> currentFilters = _filters;
          
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.filter_alt),
                SizedBox(width: 8),
                Text('Filtres de recherche'),
              ],
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SearchFilters(
                      initialFilters: currentFilters,
                      onFiltersChanged: (filters) {
                        currentFilters = filters;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _filters = currentFilters;
                  });
                  Navigator.of(context).pop();
                  // Relancer la recherche avec les nouveaux filtres
                  if (_controller.text.isNotEmpty) {
                    widget.onSearch(_controller.text, _filters);
                  }
                },
                child: const Text('Appliquer'),
              ),
            ],
          );
        },
      ),
    );
  }
}