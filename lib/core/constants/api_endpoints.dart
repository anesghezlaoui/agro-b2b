// lib/core/constants/api_endpoints.dart

import 'package:flutter/foundation.dart';

class ApiEndpoints {
  /// Build : `flutter run --dart-define=API_BASE_URL=http://<ip-serveur>:8000`
  ///
  /// Par défaut, on choisit une URL "host machine" adaptée à l'Android emulator.
  /// Pour un vrai téléphone (sur le réseau), il faut idéalement fournir `API_BASE_URL`
  /// (ex: `http://192.168.x.x:8000`).
  static const String _envBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get baseUrl =>
      _envBaseUrl.isNotEmpty ? _envBaseUrl : _defaultBaseUrl();

  static String _defaultBaseUrl() {
    if (kIsWeb) return 'http://127.0.0.1:8000';
    // Sur Android emulator, 10.0.2.2 pointe vers l'ordinateur hôte.
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    // Sur desktop/iOS simulator, localhost/127.0.0.1 fonctionne en général.
    return 'http://127.0.0.1:8000';
  }

  // Endpoints de l’API
  static const String login = '/api/login';
  static const String register = '/api/register';
  static const String me = '/api/me';
  static const String categories = '/api/categories';
  static const String produits = '/api/produits';
  static const String panier = '/api/panier';
  static const String commandes = '/api/commandes';
  static const String notifications = '/api/notifications';
}
