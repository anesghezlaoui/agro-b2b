// lib/core/constants/api_endpoints.dart

class ApiEndpoints {
  /// Build : `flutter run --dart-define=API_BASE_URL=https://votre-api.example`
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  // Endpoints de l’API
  static const String login = '/api/login';
  static const String register = '/api/register';
  static const String produits = '/api/produits';
  static const String panier = '/api/panier';
  static const String commandes = '/api/commandes';
  static const String notifications = '/api/notifications';
}
