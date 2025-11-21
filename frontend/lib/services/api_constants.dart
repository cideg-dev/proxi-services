// frontend/lib/services/api_constants.dart
// URLs des fonctions Supabase
class ApiConstants {
  static const String baseUrl = 'https://ufeqnnbokyalwjfskhmw.supabase.co/functions/v1';

  // URLs spécifiques pour chaque fonction
  static const String signupUrl = '$baseUrl/signup';
  static const String signinUrl = '$baseUrl/signin';
  static const String artisansUrl = '$baseUrl/artisans';
  static const String reviewsUrl = '$baseUrl/reviews';
}
