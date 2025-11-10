class ApiConstants {
  // Use environment variable or default to localhost for development
  static const String baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:10000/api');
}