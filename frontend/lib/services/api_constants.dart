// frontend/lib/services/api_constants.dart
// URLs des fonctions Supabase
class ApiConstants {
  static const String baseUrl = 'https://ufeqnnbokyalwjfskhmw.supabase.co/functions/v1';

  // URLs spécifiques pour chaque fonction
  static const String signupUrl = '$baseUrl/signup';
  static const String signinUrl = '$baseUrl/signin';
  static const String artisansUrl = '$baseUrl/artisans';
  static const String reviewsUrl = '$baseUrl/reviews';

  // Pour les services existants qui utilisent encore les anciens endpoints
  // Ces chemins sont maintenant redirigés vers les fonctions Supabase
  static const String authLoginEndpoint = '/auth/login';
  static const String authRegisterEndpoint = '/auth/register';
  static const String artisansEndpoint = '/artisans';
}
