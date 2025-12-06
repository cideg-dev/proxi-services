import 'package:frontend/models/user_model.dart';

class Artisan extends User {
  final String? specialty;
  final String? description;
  final int? yearsExperience;
  final String? openingHours; // Or Map/Schedule object
  final List<String>? languages;
  final bool? professionalInsurance;
  final String? siret;
  final String? website;
  final double? averageRating;
  final int? reviewCount;
  final List<dynamic>? portfolio; // Can be List<PortfolioItem> later
  final List<dynamic>? services; // Can be List<ServiceItem> later
  final List<String>? certifications;

  Artisan({
    required super.id,
    required super.email,
    super.name,
    super.role,
    super.phoneNumber,
    super.avatarUrl,
    super.coverImage,
    super.address,
    super.city,
    super.latitude,
    super.longitude,
    super.isOnline,
    super.lastSeen,
    super.createdAt,
    this.specialty,
    this.description,
    this.yearsExperience,
    this.openingHours,
    this.languages,
    this.professionalInsurance,
    this.siret,
    this.website,
    this.averageRating,
    this.reviewCount,
    this.portfolio,
    this.services,
    this.certifications,
  });

  factory Artisan.fromJson(Map<String, dynamic> json) {
    // Extract User fields
    final user = User.fromJson(json);

    return Artisan(
      id: user.id,
      email: user.email,
      name: user.name,
      role: user.role,
      phoneNumber: user.phoneNumber,
      avatarUrl: user.avatarUrl,
      coverImage: user.coverImage,
      address: user.address,
      city: user.city,
      latitude: user.latitude,
      longitude: user.longitude,
      isOnline: user.isOnline,
      lastSeen: user.lastSeen,
      createdAt: user.createdAt,
      specialty: json['specialite'] ?? json['specialty'],
      description: json['description'],
      yearsExperience: json['annees_experience'] is int ? json['annees_experience'] : int.tryParse(json['annees_experience']?.toString() ?? ''),
      openingHours: json['horaires_ouverture'] is String ? json['horaires_ouverture'] : null, // Handle Map if needed
      languages: json['langues_parlees'] != null ? List<String>.from(json['langues_parlees']) : null,
      professionalInsurance: json['assurance_professionnelle'],
      siret: json['siret'],
      website: json['site_web'],
      averageRating: (json['note_moyenne'] ?? json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['nombre_avis'] ?? json['reviewCount'] ?? 0,
      portfolio: json['portfolio'] as List<dynamic>?,
      services: json['services'] as List<dynamic>?,
      certifications: json['certifications'] != null ? List<String>.from(json['certifications']) : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final userJson = super.toJson();
    return {
      ...userJson,
      'specialite': specialty,
      'description': description,
      'annees_experience': yearsExperience,
      'horaires_ouverture': openingHours,
      'langues_parlees': languages,
      'assurance_professionnelle': professionalInsurance,
      'siret': siret,
      'site_web': website,
      'note_moyenne': averageRating,
      'nombre_avis': reviewCount,
      'portfolio': portfolio,
      'services': services,
      'certifications': certifications,
    };
  }
}
