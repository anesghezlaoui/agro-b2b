import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../models/cart_item.dart';
import '../../models/order.dart';

class OrdersRepository {
  OrdersRepository(this._apiClient);
  final ApiClient _apiClient;

  Future<List<Order>> fetchOrders() async {
    final json = await _apiClient.getJson(ApiEndpoints.commandes);
    final raw = json['results'] ?? json['items'] ?? json['data'] ?? <dynamic>[];
    if (raw is! List) return <Order>[];
    return raw.whereType<Map<String, dynamic>>().map(Order.fromJson).toList();
  }

  Future<Order?> createOrder({
    required List<CartItem> cartItems,
    required DeliveryType deliveryType,
  }) async {
    final body = {
      'delivery_type': deliveryType.name,
      'items': cartItems
          .map(
            (item) => {
              'product_id': item.product.id,
              'quantity': item.quantity,
            },
          )
          .toList(),
    };
    final json = await _apiClient.postJson(ApiEndpoints.commandes, body: body);
    final orderPayload =
        (json['order'] ?? json['data'] ?? json) as Map<String, dynamic>?;
    if (orderPayload == null) return null;
    return Order.fromJson(orderPayload);
  }
}
