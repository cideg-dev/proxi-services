import 'package:flutter/material.dart';
import 'package:frontend/services/artisan_service.dart';
import 'package:frontend/screens/artisan_detail_screen.dart';

class ProfessionalsListScreen extends StatefulWidget {
  const ProfessionalsListScreen({super.key});

  @override
  State<ProfessionalsListScreen> createState() => _ProfessionalsListScreenState();
}

class _ProfessionalsListScreenState extends State<ProfessionalsListScreen> {
  final ArtisanService _artisanService = ArtisanService();
  late Future<List<dynamic>> _professionalsFuture;

  @override
  void initState() {
    super.initState();
    _professionalsFuture = _artisanService.getArtisans();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Professionnels'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _professionalsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Erreur de chargement des professionnels:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucun professionnel trouvé.'));
          }

          final professionals = snapshot.data!;

          return ListView.builder(
            itemCount: professionals.length,
            itemBuilder: (context, index) {
              final professional = professionals[index];
              final bool isArtisan = professional['role'] == 'artisan';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                elevation: 4,
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(isArtisan ? Icons.construction : Icons.store),
                  ),
                  title: Text(professional['name'] ?? 'Nom non disponible'),
                  subtitle: Text(professional['specialty'] ?? 'Information non disponible'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ArtisanDetailScreen(artisanId: professional['id']),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
