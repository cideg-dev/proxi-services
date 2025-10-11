import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:frontend/services/artisan_service.dart'; // Assuming this service handles portfolio API calls
import 'package:frontend/services/api_constants.dart';
import 'package:frontend/services/token_manager.dart';

class ArtisanPortfolioScreen extends StatefulWidget {
  const ArtisanPortfolioScreen({super.key});

  @override
  State<ArtisanPortfolioScreen> createState() => _ArtisanPortfolioScreenState();
}

class _ArtisanPortfolioScreenState extends State<ArtisanPortfolioScreen> {
  final ArtisanService _artisanService = ArtisanService();
  late Future<List<dynamic>> _portfolioFuture;
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  final TextEditingController _captionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _portfolioFuture = _fetchPortfolio();
  }

  Future<List<dynamic>> _fetchPortfolio() async {
    final userId = await TokenManager().getUserId();
    if (userId == null) {
      // Handle error: user not logged in or ID not found
      return [];
    }
    return _artisanService.getArtisanPortfolio(userId);
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _imageFile = File(pickedFile.path);
      } else {
        
      }
    });
  }

  Future<void> _addPortfolioItem() async {
    if (_imageFile == null || _captionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une image et ajouter une description.')),
      );
      return;
    }

    final userId = await TokenManager().getUserId();
    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur: Utilisateur non connecté.')),
      );
      return;
    }

    try {
      await _artisanService.addPortfolioItem(userId, _imageFile!, _captionController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Élément de portfolio ajouté avec succès !')),
      );
      setState(() {
        _imageFile = null;
        _captionController.clear();
        _portfolioFuture = _fetchPortfolio(); // Refresh portfolio list
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'ajout: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Portfolio'),
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _portfolioFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Erreur: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Aucun élément dans le portfolio.'));
                }

                final portfolioItems = snapshot.data!;

                return GridView.builder(
                  padding: const EdgeInsets.all(8.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                  ),
                  itemCount: portfolioItems.length,
                  itemBuilder: (context, index) {
                    final item = portfolioItems[index];
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          Expanded(
                            child: Image.network(
                              '${ApiConstants.baseUrl}${item['image_url']}',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(item['caption'] ?? ''),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                _imageFile != null
                    ? Image.file(_imageFile!, height: 100)
                    : ElevatedButton(
                        onPressed: _pickImage,
                        child: const Text('Sélectionner une image'),
                      ),
                TextField(
                  controller: _captionController,
                  decoration: const InputDecoration(labelText: 'Description de l\'image'),
                ),
                ElevatedButton(
                  onPressed: _addPortfolioItem,
                  child: const Text('Ajouter au Portfolio'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
