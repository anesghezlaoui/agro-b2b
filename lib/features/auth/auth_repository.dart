import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';

class AuthRepository {
  AuthRepository(this._apiClient);
  final ApiClient _apiClient;

  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) {
    return _apiClient.postJson(
      ApiEndpoints.login,
      auth: false,
      body: {'phone': phone, 'password': password},
    );
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    required String password,
  }) {
    return _apiClient.postJson(
      ApiEndpoints.register,
      auth: false,
      body: {'name': name, 'phone': phone, 'password': password},
    );
  }

  Future<Map<String, dynamic>> fetchSession() {
    return _apiClient.getJson(ApiEndpoints.me);
  }
}
