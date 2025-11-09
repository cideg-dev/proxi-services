import 'package:flutter/material.dart';
import 'package:frontend/services/merchant_service.dart';
import 'package:frontend/widgets/merchants_grid.dart';
import 'package:frontend/services/location_service.dart';

class MerchantsScreen extends StatefulWidget {
  const MerchantsScreen({super.key});

  @override
  State<MerchantsScreen> createState() => _MerchantsScreenState();
}

class _MerchantsScreenState extends State<MerchantsScreen> {
  final MerchantService _merchantService = MerchantService();
  final LocationService _locationService = LocationService();
  
  List<dynamic> _merchants = [];
  bool _isLoading = true;
  bool _showMap = false;
  String _errorMessage = '';
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadMerchants();
  }

  Future<void> _loadMerchants() async {
    try {
      List<dynamic> merchants;
      
      if (_selectedCategory != null) {
        merchants = await _merchantService.getMerchantByCategory(_selectedCategory!);
      } else {
        merchants = await _merchantService.getMerchants();
      }
      
      setState(() {
        _merchants = merchants;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des commerçants: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Commerçants à proximité'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 60, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadMerchants,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Barre de recherche
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Rechercher un commerçant...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                    // Filtre par catégorie
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Catégorie',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                        ),
                        value: _selectedCategory,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Toutes les catégories')),
                          const DropdownMenuItem(value: 'alimentaire', child: Text('Alimentaire')),
                          const DropdownMenuItem(value: 'habillement', child: Text('Habillement')),
                          const DropdownMenuItem(value: 'électronique', child: Text('Électronique')),
                          const DropdownMenuItem(value: 'maison', child: Text('Maison & Jardin')),
                          const DropdownMenuItem(value: 'automobile', child: Text('Automobile')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value;
                            _loadMerchants();
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Affichage des commerçants
                    Expanded(
                      child: MerchantsGrid(
                        limit: 0, // Pas de limite
                        category: _selectedCategory,
                      ),
                    ),
                  ],
                ),
    );
  }
}