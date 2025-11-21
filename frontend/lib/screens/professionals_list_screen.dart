import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:frontend/services/artisan_service.dart';
import 'package:frontend/screens/artisan_detail_screen.dart';
import 'package:lottie/lottie.dart';
import 'package:frontend/widgets/empty_state.dart';

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
            return Center(child: Lottie.asset('assets/lottie/loading.json', width: 150, height: 150));
          }
          if (snapshot.hasError) {
            return EmptyState(message: 'Une erreur est survenue lors du chargement des professionnels.\n${snapshot.error}');
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const EmptyState(message: 'Aucun professionnel trouvé pour le moment.');
          }

          final professionals = snapshot.data!;

          return ListView.builder(
            itemCount: professionals.length,
            itemBuilder: (context, index) {
              final professional = professionals[index];
              final bool isArtisan = professional['role'] == 'artisan';

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        ),
                      ),
                      child: ListTile(
                        leading: Hero(
                          tag: 'artisan-avatar-${professional['id']}',
                          child: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                            foregroundColor: Theme.of(context).colorScheme.primary,
                            child: Icon(isArtisan ? Icons.construction : Icons.store),
                          ),
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
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
