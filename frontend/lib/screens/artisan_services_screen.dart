import 'package:flutter/material.dart';
import 'package:frontend/services/artisan_service.dart';

class ArtisanServicesScreen extends StatefulWidget {
  const ArtisanServicesScreen({super.key});

  @override
  State<ArtisanServicesScreen> createState() => _ArtisanServicesScreenState();
}

class _ArtisanServicesScreenState extends State<ArtisanServicesScreen> {
  final ArtisanService _artisanService = ArtisanService();
  late Future<List<dynamic>> _servicesFuture;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  void _loadServices() {
    setState(() {
      _servicesFuture = _artisanService.getMyArtisanServices();
    });
  }

  void _showServiceDialog({Map<String, dynamic>? service}) {
    final _formKey = GlobalKey<FormState>();
    final _nomController = TextEditingController(text: service?['nom']);
    final _descriptionController = TextEditingController(text: service?['description']);
    final _tarifController = TextEditingController(text: service?['tarif']?.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(service == null ? 'Ajouter un service' : 'Modifier le service'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nomController,
                  decoration: const InputDecoration(labelText: 'Nom du service'),
                  validator: (value) => value!.isEmpty ? 'Champ requis' : null,
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: (value) => value!.isEmpty ? 'Champ requis' : null,
                ),
                TextFormField(
                  controller: _tarifController,
                  decoration: const InputDecoration(labelText: 'Tarif'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? 'Champ requis' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final serviceData = {
                    'nom': _nomController.text,
                    'description': _descriptionController.text,
                    'tarif': double.parse(_tarifController.text),
                  };

                  try {
                    if (service == null) {
                      await _artisanService.addArtisanService(serviceData);
                    } else {
                      await _artisanService.updateArtisanService(service['id'], serviceData);
                    }
                    Navigator.pop(context);
                    _loadServices(); // Refresh the list
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }

  void _deleteService(int serviceId) async {
    try {
      await _artisanService.deleteArtisanService(serviceId);
      _loadServices(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Services'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showServiceDialog(),
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _servicesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucun service trouvé. Appuyez sur + pour en ajouter un.'));
          }

          final services = snapshot.data!;

          return ListView.builder(
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return ListTile(
                title: Text(service['nom'] ?? 'Sans nom'),
                subtitle: Text(service['description'] ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${service['tarif']} €'),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showServiceDialog(service: service),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteService(service['id']),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}