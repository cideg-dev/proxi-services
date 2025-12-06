import 'package:flutter/material.dart';
import 'package:frontend/services/artisan_service.dart';
import 'package:frontend/services/qa_service.dart';
import 'package:frontend/services/token_manager.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:frontend/services/api_constants.dart';
import 'dart:ui'; // For BackdropFilter
import 'package:frontend/widgets/glass_card.dart';
import 'package:lottie/lottie.dart';
import 'package:frontend/widgets/empty_state.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:frontend/screens/portfolio_item_detail_screen.dart';

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
  int? _currentUserId; // To check if the current user is the owner
  bool _isOwner = false; // To show owner-specific actions

  @override
  void initState() {
    super.initState();
    // Fetch main professional data first
    _dataFuture = _fetchProfessionalDetails();
    // Then load secondary data independently
    _loadSecondaryData();
    _loadUserData();
  }

  Future<Map<String, dynamic>> _fetchProfessionalDetails() async {
    final professionalData = await _artisanService.getArtisanById(widget.artisanId);
    _checkFavoriteStatus(professionalData['id']); // Check favorite status after loading details
    return professionalData;
  }

  void _loadSecondaryData() async {
    // Load reviews
    try {
      final reviews = await _artisanService.getArtisanReviews(widget.artisanId);
      if (mounted) setState(() => _professionalReviews = reviews);
    } catch (e) {
      print('Failed to load reviews: $e');
      if (mounted) setState(() => _professionalReviews = []); // Ensure it's an empty list on error
    }

    // Load portfolio
    try {
      final portfolio = await _artisanService.getArtisanPortfolio(widget.artisanId);
      if (mounted) setState(() => _professionalPortfolio = portfolio);
    } catch (e) {
      print('Failed to load portfolio: $e');
      if (mounted) setState(() => _professionalPortfolio = []); // Ensure it's an empty list on error
    }

    // Load services
    try {
      final services = await _artisanService.getArtisanServices(widget.artisanId);
      if (mounted) setState(() => _professionalServices = services);
    } catch (e) {
      print('Failed to load services: $e');
      if (mounted) setState(() => _professionalServices = []); // Ensure it's an empty list on error
    }

    // Load questions
    try {
      final questions = await _qaService.getQuestions(widget.artisanId);
      if (mounted) setState(() => _questions = questions);
    } catch (e) {
      print('Failed to load questions: $e');
      if (mounted) setState(() => _questions = []); // Ensure it's an empty list on error
    }
  }

  void _loadUserData() async {
    final role = await _tokenManager.getUserRole();
    final userId = await _tokenManager.getUserId();
    if (mounted) {
      setState(() {
        _userRole = role;
        _currentUserId = userId;
        _isOwner = _currentUserId != null && _currentUserId == widget.artisanId;
      });
    }
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
            return Center(child: Lottie.asset('assets/lottie/loading.json', width: 150, height: 150));
          }
          if (snapshot.hasError) {
            return EmptyState(message: 'Erreur de chargement: ${snapshot.error}');
          }
          if (!snapshot.hasData) {
            return const EmptyState(message: 'Professionnel non trouvé.');
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
      floatingActionButton: _isOwner ? _buildGeneratePortfolioButton() : null,
    );
  }

  Widget _buildGeneratePortfolioButton() {
    return FloatingActionButton.extended(
      onPressed: () {
        // We need professional data to pre-fill the description
        _dataFuture.then((professional) {
          if (professional.isNotEmpty) {
            _showGeneratePortfolioDialog(professional);
          }
        });
      },
      label: const Text('Générer Portfolio'),
      icon: const Icon(Icons.auto_awesome),
      backgroundColor: Theme.of(context).colorScheme.secondary,
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
          ? const EmptyState(message: 'Aucun avis pour le moment.')
          : Column(
              children: _professionalReviews.map((review) {
                return GlassCard(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(review['comment']),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('${review['client_name']} - ${review['rating']}/5', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ],
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
          ? const EmptyState(message: 'Aucun élément de portfolio pour le moment.')
          : MasonryGridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              itemCount: _professionalPortfolio.length,
              itemBuilder: (context, index) {
                final item = _professionalPortfolio[index];
                final heroTag = 'portfolio-image-${item['id']}';

                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => PortfolioItemDetailScreen(item: item),
                    ));
                  },
                  child: Hero(
                    tag: heroTag,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            // CORRECTED: Use the full URL directly from the backend
                            item['image_url'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Colors.grey[800],
                              child: const Icon(Icons.broken_image, color: Colors.white70, size: 40),
                            ),
                          ),
                          // Add a gradient overlay for text readability
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          // Positioned text for the item name
                          Positioned(
                            bottom: 8,
                            left: 8,
                            right: 8,
                            child: Text(
                              item['name'] ?? '',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
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
          ? const EmptyState(message: 'Aucune question pour le moment. Soyez le premier à en poser une !')
          : Column(
              children: _questions.map((q) {
                return GlassCard(
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
          ? const EmptyState(message: 'Aucun service proposé pour le moment.')
          : Column(
              children: _professionalServices.map((service) {
                return GlassCard(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(service['name'], style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(service['description']),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text('${service['price']} €', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary)),
                      ),
                    ],
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

  // --- AI Portfolio Generation Logic ---

  void _showGeneratePortfolioDialog(Map<String, dynamic> professional) {
    final descriptionController = TextEditingController(
      text: professional['description'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Générer le Portfolio par IA'),
          content: TextField(
            controller: descriptionController,
            decoration: const InputDecoration(
              labelText: 'Décrivez votre activité',
              hintText: 'Ex: Je suis un boulanger passionné par le levain naturel...',
            ),
            maxLines: 5,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _triggerPortfolioGeneration(descriptionController.text);
              },
              child: const Text('Générer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _triggerPortfolioGeneration(String description) async {
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La description ne peut pas être vide.'), backgroundColor: Colors.red),
      );
      return;
    }

    // Show a loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: Lottie.asset('assets/lottie/loading.json', width: 150, height: 150)),
    );

    try {
      // This service method needs to be created
      await _artisanService.generateAIPortfolio(description);

      Navigator.of(context).pop(); // Dismiss loading indicator

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Portfolio généré avec succès ! Rechargement...'), backgroundColor: Colors.green),
      );

      // Reload all data to show the new portfolio
      setState(() {
        _dataFuture = _fetchProfessionalDetails();
        _loadSecondaryData();
      });

    } catch (e) {
      Navigator.of(context).pop(); // Dismiss loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
