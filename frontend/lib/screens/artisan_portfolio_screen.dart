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
  final TokenManager _tokenManager = TokenManager();
  late Future<List<dynamic>> _portfolioFuture;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _portfolioFuture = _fetchPortfolio();
  }

  Future<List<dynamic>> _fetchPortfolio() async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      // This will be caught by the FutureBuilder
      throw Exception("Utilisateur non connecté ou ID introuvable.");
    }
    return _artisanService.getArtisanPortfolio(userId);
  }

  Future<void> _showAddPortfolioItemDialog() async {
    final userRole = await _tokenManager.getUserRole();
    File? imageFile;
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> pickImage() async {
              final pickedFile = await _picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 70,
                  maxWidth: 800);
              if (pickedFile != null) {
                setState(() {
                  imageFile = File(pickedFile.path);
                });
              }
            }

            return AlertDialog(
              title: const Text('Ajouter une réalisation'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      // Image preview and picker
                      Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[700]!),
                        ),
                        child: imageFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(imageFile!, fit: BoxFit.cover),
                              )
                            : Center(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.photo_library),
                                  label: const Text('Choisir une image'),
                                  onPressed: pickImage,
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor:
                                        Theme.of(context).colorScheme.secondary,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),
                      // Name field
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nom de la réalisation',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'Le nom est requis.'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      // Description / Explanation field
                      TextFormField(
                        controller: descriptionController,
                        decoration: InputDecoration(
                          labelText: userRole == 'commercant'
                              ? 'Description'
                              : 'Explication',
                          border: const OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'La description/explication est requise.'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      // Price field (for merchants only)
                      if (userRole == 'commercant')
                        TextFormField(
                          controller: priceController,
                          decoration: const InputDecoration(
                              labelText: 'Prix (optionnel)',
                              prefixText: 'CFA ',
                              border: OutlineInputBorder()),
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                        ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Annuler'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  child: const Text('Ajouter'),
                  onPressed: () async {
                    if (imageFile == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Veuillez sélectionner une image.')),
                      );
                      return;
                    }
                    if (formKey.currentState!.validate()) {
                      final userId = await _tokenManager.getUserId();
                      if (!mounted || userId == null) return;

                      // Pop dialog before async operation to avoid context issues
                      Navigator.of(context).pop();

                      try {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ajout en cours...')),
                        );

                        await _artisanService.addPortfolioItem(
                          userId,
                          imageFile!,
                          nameController.text,
                          descriptionController.text,
                          priceController.text,
                        );

                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Élément ajouté avec succès !')),
                        );

                        // Refresh portfolio list
                        super.setState(() {
                          _portfolioFuture = _fetchPortfolio();
                        });
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('Erreur lors de l\'ajout: ${e.toString()}')),
                        );
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Portfolio'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _portfolioFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text(
                    'Aucun élément. Appuyez sur + pour en ajouter.'));
          }

          final portfolioItems = snapshot.data!;

          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 0.75, // Adjust aspect ratio for new text
            ),
            itemCount: portfolioItems.length,
            itemBuilder: (context, index) {
              final item = portfolioItems[index];
              // Use new fields: name, description, price. Fallback to old 'caption' if needed.
              final name = item['name'] ?? 'Projet';
              final description = item['description'] ?? item['caption'] ?? '';
              final price = item['price'];

              return Card(
                clipBehavior: Clip.antiAlias,
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Image.network(
                        item['image_url'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image, size: 40),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: Theme.of(context).textTheme.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(description,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                          if (price != null && price.toString().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text('$price CFA',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary)),
                          ]
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPortfolioItemDialog,
        tooltip: 'Ajouter une réalisation',
        child: const Icon(Icons.add),
      ),
    );
  }
}

