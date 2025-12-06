import 'package:flutter/material.dart';
import 'package:frontend/services/artisan_service.dart';
import 'package:frontend/services/review_service.dart';
import 'package:frontend/widgets/star_rating.dart';
import 'package:frontend/widgets/reviews_list.dart';
import 'package:frontend/models/artisan_model.dart';

class DetailedProfileWidget extends StatefulWidget {
  final int userId;
  final bool isOwnProfile;

  const DetailedProfileWidget({
    super.key,
    required this.userId,
    this.isOwnProfile = false,
  });

  @override
  State<DetailedProfileWidget> createState() => _DetailedProfileWidgetState();
}

class _DetailedProfileWidgetState extends State<DetailedProfileWidget> {
  final ArtisanService _artisanService = ArtisanService();
  final ReviewService _reviewService = ReviewService();
  
  Artisan? _profile;
  List<dynamic> _reviews = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadReviews();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _artisanService.getArtisanById(widget.userId);
      
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement du profil: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadReviews() async {
    try {
      final reviews = await _reviewService.getArtisanReviews(widget.userId);
      
      setState(() {
        _reviews = reviews;
      });
    } catch (e) {
      print('Erreur lors du chargement des avis: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
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
              onPressed: _loadProfile,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_profile == null) {
      return const Center(
        child: Text('Profil non trouvé'),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image de couverture
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  _profile!.coverImage ?? 'https://via.placeholder.com/800x300',
                ),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(
                      _profile!.avatarUrl ?? 'https://via.placeholder.com/150',
                    ),
                    backgroundColor: Colors.grey[300],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Informations de base
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _profile!.name ?? _profile!.email ?? 'Utilisateur',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _profile!.specialty ?? 'Professionnel',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Étoiles et note
                Row(
                  children: [
                    StarRating(
                      rating: (_profile!.averageRating ?? 0.0).toDouble(),
                      allowHalfRating: true,
                      allowEditing: false,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${(_profile!.averageRating ?? 0.0).toStringAsFixed(1)}/5.0)',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${_profile!.reviewCount ?? 0} avis)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Description
                if (_profile!.description != null && _profile!.description!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'À propos',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _profile!.description!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // Informations professionnelles
                _buildInfoSection('Localisation', _profile!.city ?? 'Non spécifiée'),
                _buildInfoSection('Téléphone', _profile!.phoneNumber ?? 'Non spécifié'),
                _buildInfoSection('Email', _profile!.email),
                
                // Certifications
                if (_profile!.certifications?.isNotEmpty == true)
                  _buildCertificationsSection(_profile!.certifications!),
                
                // Horaires
                if (_profile!.openingHours != null)
                  _buildScheduleSection(_profile!.openingHours!),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Avis
          ReviewsList(
            reviews: _reviews,
            showAddReviewButton: !widget.isOwnProfile,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _getIconForTitle(title),
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificationsSection(List<String> certifications) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Certifications',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: certifications.map((cert) => 
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  cert,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 12,
                  ),
                ),
              ),
            ).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSection(dynamic schedule) {
    // Handle string schedule (e.g. "08:00 - 18:00") or map schedule
    if (schedule is String) {
       return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Horaires',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(schedule),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Horaires',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          ..._buildScheduleItems(schedule),
        ],
      ),
    );
  }

  List<Widget> _buildScheduleItems(dynamic schedule) {
    final items = <Widget>[];
    final weekDays = {
      'monday': 'Lundi',
      'tuesday': 'Mardi',
      'wednesday': 'Mercredi',
      'thursday': 'Jeudi',
      'friday': 'Vendredi',
      'saturday': 'Samedi',
      'sunday': 'Dimanche',
    };

    // If schedule is a Map, iterate keys
    if (schedule is Map) {
      weekDays.forEach((key, day) {
        final daySchedule = schedule[key];
        if (daySchedule != null) {
          String scheduleText;
          if (daySchedule['isOpen'] == false) {
            scheduleText = 'Fermé';
          } else {
            final open = daySchedule['open'] ?? 'N/A';
            final close = daySchedule['close'] ?? 'N/A';
            scheduleText = '$open - $close';
          }

          items.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Row(
                children: [
                  Text(
                    '$day: ',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(scheduleText),
                ],
              ),
            ),
          );
        }
      });
    }

    return items;
  }

  IconData _getIconForTitle(String title) {
    switch (title.toLowerCase()) {
      case 'localisation':
        return Icons.location_on;
      case 'téléphone':
        return Icons.phone;
      case 'email':
        return Icons.email;
      default:
        return Icons.info;
    }
  }
}