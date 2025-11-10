class ApiConstants {
  // Use environment variable or default to production URL for deployment
  static const String baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'https://proxi-services.onrender.com/api');
}