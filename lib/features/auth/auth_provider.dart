import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/network/api_client.dart';
import '../../core/utils/phone_utils.dart';
import 'auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repository, this._apiClient);

  final AuthRepository _repository;
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isAuthenticated = false;
  bool _isValidatedByAdmin = false;
  bool _bootstrapped = false;
  bool _isLoading = false;
  String? _errorMessage;
  String _name = '';
  String _phone = '';

  /// Devient vrai après lecture du stockage (évite écran blanc / état incohérent au 1er frame).
  bool get isBootstrapped => _bootstrapped;

  bool get isAuthenticated => _isAuthenticated;
  bool get isValidatedByAdmin => _isValidatedByAdmin;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get name => _name;
  String get phone => _phone;

  Future<void> init() async {
    try {
      final token = await _storage.read(key: 'token');
      if (token != null && token.isNotEmpty) {
        _isAuthenticated = true;
        _name = await _storage.read(key: 'name') ?? 'Client';
        _phone = await _storage.read(key: 'phone') ?? '';
        _isValidatedByAdmin =
            (await _storage.read(key: 'is_validated'))?.toLowerCase() == 'true';
      }
    } catch (_) {
      // Web (crypto / stockage) ou plateforme non prise en charge : rester déconnecté.
    } finally {
      _bootstrapped = true;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String name,
    required String phone,
    required String password,
  }) async {
    phone = digitsOnlyPhone(phone);
    if (!_isValidPhone(phone) || password.length < 6 || name.trim().isEmpty) {
      _errorMessage = 'Vérifie les champs saisis.';
      notifyListeners();
      return false;
    }
    _setLoading(true);
    _errorMessage = null;
    try {
      final data = await _repository.register(
        name: name.trim(),
        phone: phone.trim(),
        password: password,
      );
      final token = (data['token'] ?? data['access'] ?? '').toString();
      if (token.isEmpty) {
        _errorMessage = 'Réponse inscription invalide (token manquant).';
        return false;
      }
      _name = (data['name'] ?? data['nom'] ?? name).toString();
      _phone = (data['phone'] ?? data['telephone'] ?? phone).toString();
      _isValidatedByAdmin = (data['is_validated'] ?? false) == true;
      _isAuthenticated = true;
      await _apiClient.saveToken(token);
      await _storage.write(key: 'phone', value: _phone);
      await _storage.write(key: 'name', value: _name);
      await _storage.write(key: 'is_validated', value: '$_isValidatedByAdmin');
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Inscription impossible, vérifie la connexion.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login({required String phone, required String password}) async {
    phone = digitsOnlyPhone(phone.trim());
    if (!_isValidPhone(phone) || password.isEmpty) {
      _errorMessage = 'Téléphone ou mot de passe invalide.';
      notifyListeners();
      return false;
    }
    _setLoading(true);
    _errorMessage = null;
    try {
      final data = await _repository.login(
        phone: phone.trim(),
        password: password,
      );
      final token = (data['token'] ?? data['access'] ?? '').toString();
      if (token.isEmpty) {
        _errorMessage = 'Réponse login invalide (token manquant).';
        return false;
      }
      _name = (data['name'] ?? data['nom'] ?? 'Client').toString();
      _phone = (data['phone'] ?? data['telephone'] ?? phone).toString();
      _isValidatedByAdmin = (data['is_validated'] ?? false) == true;
      _isAuthenticated = true;
      await _apiClient.saveToken(token);
      await _storage.write(key: 'phone', value: _phone);
      await _storage.write(key: 'name', value: _name);
      await _storage.write(key: 'is_validated', value: '$_isValidatedByAdmin');
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Connexion impossible, vérifie le serveur API.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> markValidatedByAdmin() async {
    _isValidatedByAdmin = true;
    await _storage.write(key: 'is_validated', value: 'true');
    notifyListeners();
  }

  /// Recharge le statut depuis l’API (après validation par l’admin).
  Future<bool> refreshSession() async {
    try {
      final data = await _repository.fetchSession();
      _isValidatedByAdmin = (data['is_validated'] ?? false) == true;
      _name = (data['name'] ?? data['nom'] ?? _name).toString();
      _phone = (data['phone'] ?? data['telephone'] ?? _phone).toString();
      await _storage.write(key: 'is_validated', value: '$_isValidatedByAdmin');
      await _storage.write(key: 'name', value: _name);
      await _storage.write(key: 'phone', value: _phone);
      notifyListeners();
      return _isValidatedByAdmin;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _isValidatedByAdmin = false;
    await _apiClient.clearToken();
    await _storage.delete(key: 'name');
    await _storage.delete(key: 'phone');
    await _storage.delete(key: 'is_validated');
    notifyListeners();
  }

  bool _isValidPhone(String phone) {
    final digitsOnly = RegExp(r'^\d{10}$');
    return digitsOnly.hasMatch(phone.trim());
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
