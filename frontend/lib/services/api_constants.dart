// frontend/lib/services/api_constants.dart
// URLs de configuration pour l'API
class ApiConstants {
  // Configuration pour basculer entre local et production
  static const bool useLocalBackend = bool.fromEnvironment('USE_LOCAL_BACKEND', defaultValue: false);

  // URLs de base
  static const String localBaseUrl = 'http://localhost:3000'; // ou l'URL de votre backend local
  static const String supabaseBaseUrl = 'https://ufeqnnbokyalwjfskhmw.supabase.co/functions/v1';

  // Sélectionner l'URL de base en fonction de la configuration
  static const String baseUrl = useLocalBackend ? localBaseUrl : supabaseBaseUrl;

  // URLs spécifiques pour chaque fonction
  static const String signupUrl = useLocalBackend
      ? '$localBaseUrl/api/auth/register'
      : '$supabaseBaseUrl/signup';
  static const String signinUrl = useLocalBackend
      ? '$localBaseUrl/api/auth/login'
      : '$supabaseBaseUrl/signin';
  static const String logoutUrl = useLocalBackend
      ? '$localBaseUrl/api/auth/logout'
      : '$supabaseBaseUrl/logout';
  static const String artisansUrl = useLocalBackend
      ? '$localBaseUrl/api/artisans'
      : '$supabaseBaseUrl/artisans';
  static const String reviewsUrl = useLocalBackend
      ? '$localBaseUrl/api/reviews'
      : '$supabaseBaseUrl/reviews';

  // Pour les services existants qui utilisent encore les anciens endpoints
  static const String authLoginEndpoint = '/api/auth/login';
  static const String authRegisterEndpoint = '/api/auth/register';
  static const String artisansEndpoint = '/api/artisans';
  static const String demands = '/demands'; // Added for DashboardService
}
