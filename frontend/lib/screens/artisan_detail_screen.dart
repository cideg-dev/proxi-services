import 'package:flutter/material.dart';
import 'package:frontend/services/artisan_service.dart';
import 'package:frontend/services/qa_service.dart';
import 'package:frontend/services/token_manager.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:frontend/services/api_constants.dart';
import 'dart:ui'; // For BackdropFilter

class ArtisanDetailScreen extends StatefulWidget {
  final int artisanId;

  const ArtisanDetailScreen({Key? key, required this.artisanId}) : super(key: key);

  @override
  _ArtisanDetailScreenState createState() => _ArtisanDetailScreenState();
}

class _ArtisanDetailScreenState extends State<ArtisanDetailScreen> {
  final ArtisanService _artisanService = ArtisanService();
  final QAService _qaService = QAService();
  final TokenManager _tokenManager = TokenManager();
  late Future<Map<String, dynamic>> _dataFuture;
  List<dynamic> _professionalReviews = [];
  List<dynamic> _professionalPortfolio = [];
  List<dynamic> _professionalServices = [];
  List<dynamic> _questions = [];
  bool _isFavorited = false; // New state variable for favorite status
  String? _userRole; // To check if the current user can favorite

  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchProfessionalDetails();
    _loadUserData();
  }

  Future<Map<String, dynamic>> _fetchProfessionalDetails() async {
    final results = await Future.wait([
      _artisanService.getArtisanById(widget.artisanId),
      _artisanService.getArtisanReviews(widget.artisanId),
      _artisanService.getArtisanPortfolio(widget.artisanId),
      _artisanService.getArtisanServices(widget.artisanId),
      _qaService.getQuestions(widget.artisanId),
    ]);

    setState(() {
      _professionalReviews = results[1] as List<dynamic>;
      _professionalPortfolio = results[2] as List<dynamic>;
      _professionalServices = results[3] as List<dynamic>;
      _questions = results[4] as List<dynamic>;
    });

    final professionalData = results[0] as Map<String, dynamic>;
    _checkFavoriteStatus(professionalData['id']); // Check favorite status after loading details
    return professionalData;
  }

  void _loadUserData() async {
    final role = await _tokenManager.getRole();
    setState(() {
      _userRole = role;
    });
  }

  void _checkFavoriteStatus(int professionalId) async {
    try {
      final favorites = await _artisanService.getFavoriteArtisans();
      setState(() {
        _isFavorited = favorites.any((fav) => fav['favorite_artisan_id'] == professionalId);
      });
    } catch (e) {
      print('Error checking favorite status: $e');
    }
  }

  void _toggleFavorite(int professionalId) async {
    try {
      if (_isFavorited) {
        await _artisanService.removeFavorite(professionalId);
        setState(() {
          _isFavorited = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Retiré des favoris.'), backgroundColor: Colors.red),
        );
      } else {
        await _artisanService.addFavorite(professionalId);
        setState(() {
          _isFavorited = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ajouté aux favoris !'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _shareProfessionalProfile(Map<String, dynamic> professional) {
    final String specialty = professional['specialite'] ?? professional['type_commerce'] ?? 'compétence inconnue';
    final String shareText =
        'Découvrez ${professional['nom_complet'] ?? professional['nom_entreprise']}, un expert en $specialty sur Proxi-Services !';
    // Implement actual sharing logic (e.g., using share_plus package)
    print(shareText);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du Professionnel'),
        actions: [
          if (_userRole == 'client') // Only clients can favorite
            IconButton(
              icon: Icon(
                _isFavorited ? Icons.favorite : Icons.favorite_border,
                color: _isFavorited ? Colors.red : null,
              ),
              onPressed: () => _toggleFavorite(widget.artisanId),
            ),
          // Add other actions if needed
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur de chargement: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Professionnel non trouvé.'));
          }

          final professional = snapshot.data!;
          final bool isArtisan = professional['role'] == 'artisan';

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGeneralInfoSection(professional, isArtisan),
                _buildVideoSection(professional),
                _buildReviewsSection(),
                _buildPortfolioSection(),
                _buildQandASection(),
                _buildServicesSection(),
                _buildContactButton(professional),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGeneralInfoSection(Map<String, dynamic> professional, bool isArtisan) {
    final String name = professional['nom_complet'] ?? professional['nom_entreprise'] ?? 'Nom non disponible';
    final String specialty = professional['specialite'] ?? professional['type_commerce'] ?? 'Information non disponible';
    final String description = professional['description'] ?? 'Description non disponible.';
    final String location = professional['location'] ?? 'Non spécifiée';
    final String telephone = professional['telephone'] ?? 'Non spécifié';
    final String yearsExperience = professional['annees_experience']?.toString() ?? 'N/A';
    final String siret = professional['siret'] ?? 'N/A';
    final String website = professional['site_web'] ?? 'N/A';
    final String photoUrl = professional['photo_url'] ?? '';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Hero(
                tag: 'artisan-avatar-${professional['id']}',
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: photoUrl.isNotEmpty
                      ? NetworkImage('${ApiConstants.baseUrl}$photoUrl')
                      : null,
                  child: photoUrl.isEmpty
                      ? Icon(isArtisan ? Icons.construction : Icons.store, size: 40)
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(name, style: Theme.of(context).textTheme.displaySmall)),
                        IconButton(
                          icon: const Icon(Icons.share),
                          onPressed: () => _shareProfessionalProfile(professional),
                          tooltip: 'Partager',
                        ),
                      ],
                    ),
                    Text(specialty, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(description, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.location_on, 'Localisation: $location'),
          _buildInfoRow(Icons.phone, 'Téléphone: $telephone'),
          if (isArtisan) _buildInfoRow(Icons.work, 'Années d\'experience: $yearsExperience'),
          if (!isArtisan && professional['horaires_ouverture'] != null)
            _buildInfoRow(Icons.access_time, 'Horaires: ${professional['horaires_ouverture']}'),
          _buildInfoRow(Icons.credit_card, 'SIRET: $siret'),
          if (website != 'N/A') _buildInfoRow(Icons.link, 'Site Web: $website', onTap: () => _launchURL(website)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      decoration: onTap != null ? TextDecoration.underline : null,
                      color: onTap != null ? Theme.of(context).colorScheme.primary : null,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoSection(Map<String, dynamic> professional) {
    // Placeholder for video section
    return const SizedBox.shrink();
  }

  Widget _buildReviewsSection() {
    return _buildSection(
      title: 'Avis',
      content: _professionalReviews.isEmpty
          ? const Text('Aucun avis pour le moment.')
          : Column(
              children: _professionalReviews.map((review) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ListTile(
                    title: Text(review['comment']),
                    subtitle: Text('${review['client_name']} - ${review['rating']}/5'),
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildPortfolioSection() {
    return _buildSection(
      title: 'Portfolio',
      content: _professionalPortfolio.isEmpty
          ? const Text('Aucun élément de portfolio pour le moment.')
          : GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
                childAspectRatio: 1.0,
              ),
              itemCount: _professionalPortfolio.length,
              itemBuilder: (context, index) {
                final item = _professionalPortfolio[index];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    '${ApiConstants.baseUrl}${item['image_url']}',
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
    );
  }

  Widget _buildQandASection() {
    return _buildSection(
      title: 'Questions & Réponses',
      content: _questions.isEmpty
          ? const Text('Aucune question pour le moment. Soyez le premier à en poser une !')
          : Column(
              children: _questions.map((q) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ExpansionTile(
                    title: Text(q['question_text']),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(q['answer_text'] ?? 'Pas encore de réponse.'),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildServicesSection() {
    return _buildSection(
      title: 'Services',
      content: _professionalServices.isEmpty
          ? const Text('Aucun service proposé pour le moment.')
          : Column(
              children: _professionalServices.map((service) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ListTile(
                    title: Text(service['name']),
                    subtitle: Text('${service['description']} - ${service['price']} €'),
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildContactButton(Map<String, dynamic> professional) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: () {
          // TODO: Implement chat functionality
          print('Contacter ${professional['nom_complet'] ?? professional['nom_entreprise']}');
        },
        child: const Text('Contacter le professionnel'),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget content}) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          content,
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d\'ouvrir le lien: $url')),
      );
    }
  }
}
