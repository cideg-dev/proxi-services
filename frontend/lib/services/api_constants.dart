import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  // Use runtime environment variable if available, otherwise fallback to localhost:3001
  static String get baseUrl => dotenv.env['API_URL'] ?? 'https://proxi-services.onrender.com';
  static String get kkiapayPublicKey => dotenv.env['KKIAPAY_PUBLIC_KEY'] ?? '';
  static bool get kkiapaySandbox => dotenv.env['KKIAPAY_SANDBOX'] == 'true';
}
