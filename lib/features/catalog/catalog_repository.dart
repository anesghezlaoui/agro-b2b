import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../models/product.dart';

class CatalogRepository {
  CatalogRepository(this._apiClient);
  final ApiClient _apiClient;

  Future<List<Product>> fetchProducts() async {
    final json = await _apiClient.getJson(ApiEndpoints.produits);
    final raw = _extractList(json);
    final out = <Product>[];
    for (final row in raw) {
      try {
        out.add(Product.fromJson(row));
      } catch (_) {
        // Ignore les lignes invalides pour ne pas planter tout le catalogue.
      }
    }
    return out;
  }

  List<Map<String, dynamic>> _extractList(Map<String, dynamic> json) {
    final data = json['results'] ?? json['items'] ?? json['data'] ?? json;
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    return <Map<String, dynamic>>[];
  }
}
