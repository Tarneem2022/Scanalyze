/// API configuration constants.
class ApiConstants {
  ApiConstants._();

  // Uses ADB reverse tunnel via USB to bypass Windows Firewall blocks
  static const String baseUrl = 'http://127.0.0.1:5000/api';
  // static const String baseUrl = 'http://localhost:5000/api'; // iOS simulator / web

  static const Duration timeout = Duration(seconds: 30);
}
